NAME=devpi-server
VERSION=$(shell dp_version.sh)
RELEASE=$(shell dp_release.sh)
PROJECT_NAME=$(shell dp_project_name.sh)
STABLE_BUILD=$(shell dp_is_stable_build.sh)
CI_SERVER=$(shell dp_ci-server.sh)
#sonar configuration
METRICS_FILE=sonar-project.properties
METRICS_RH_VERSION=el7

#Include all scm info in the package of the component
SCM_URL=$(shell dp_scm_info.sh >SCM_INFO)

#reports files
TARGET_DIR=target
REPORT_DIR=$(TARGET_DIR)/reports
PYLINT_REPORT=$(REPORT_DIR)/pylint.txt


#site-packages
PYTHON_INSTALLABLE=python2.7
PYTHON_SITE_REL=/lib/$(PYTHON_INSTALLABLE)/site-packages

#pip options
WHEEL_PATH=$(HOME)/.venv/wheel

platform=$(shell uname)

#pip configuration
VIRTUALENV_PATH=./.venv/$(NAME)-$(VERSION)-$(platform)
VIRTUALENV_OPTS=--python=$(PYTHON_INSTALLABLE)
DEVPI_URL=$(CI_SERVER)/devpi/develenv/dev/+simple/
#PYPI_INDEX=-i $(DEVPI_URL)
PIP=$(VIRTUALENV_PATH)/bin/python $(VIRTUALENV_PATH)/bin/pip
PIP_EXTRA_OPTS=--timeout=180 $(PYPI_INDEX) 
WHEEL_EXTRA_OPTS=--use-wheel --find-links=$(WHEEL_PATH) -r requirements.txt

PYLINT=$(VIRTUALENV_PATH)/bin/pylint



all: default 

default:
	@echo
	@echo "Welcome to $(NAME) software package"
	@echo
	@echo "   Version ${VERSION}-${RELEASE}"
	@echo
	@echo "devclean         - Remove temp files and dev virtualenv"
	@echo "distclean        - Remove temp files and rpm virtualenv"
	@echo
	@echo "install          - Installs $(NAME)"
	@echo "rpm              - Create RPM package"
	@echo 
	@echo "venv             - Creates the dev virtual env"
	@echo "devlibs          - Installs the dev libs for the dev venv"
	@echo "testlibs         - Installs the test libs for the dev venv"
	@echo 
	@echo "buildci          - Generates xunit, cover and pylint reports and build rpm"
	@echo "deployci         - Upload $(NAME) to $(DEVPI_URL)"
	@echo                                                                                                          
	@echo "pylint           -To lint code structure"  
	@echo	

testlibs: venv $(VIRTUALENV_PATH)$(PYTHON_SITE_REL)/testlibs
$(VIRTUALENV_PATH)$(PYTHON_SITE_REL)/testlibs: requirements-test.txt 
	@echo ">>> installing test libs from wheels"
	@$(PIP) install --use-wheel --no-index --find-links=$(WHEEL_PATH) -r requirements-test.txt; \
	if [ $$? -ne 0 ]; then \
		echo "wheel packages not found, downloading them"; \
		$(PIP) wheel -w $(WHEEL_PATH) --no-use-wheel $(PIP_EXTRA_OPTS) -r requirements-test.txt; \
		$(PIP) install --use-wheel --no-index --find-links=$(WHEEL_PATH) -r requirements-test.txt; \
	fi
	@if [ $$? -eq 0 ]; then \
		touch $(VIRTUALENV_PATH)$(PYTHON_SITE_REL)/testlibs; fi

tests: devlibs testlibs
	@echo

pylint: $(PYLINT)
	@echo ">>> Pylint report"
	@mkdir -p $(REPORT_DIR)
	$(PYLINT) src/cdn --ignore=tests > $(PYLINT_REPORT) || echo ">>> pylint done"

venv: $(VIRTUALENV_PATH)/bin/activate
$(VIRTUALENV_PATH)/bin/activate:
	@echo ">>> checking virtualpath"
	@test -d $(VIRTUALENV_PATH) || PYTHONPATH= virtualenv -p $(PYTHON_INSTALLABLE) $(VIRTUALENV_PATH)
	@$(PIP) install --upgrade pip $(PIP_EXTRA_OPTS)
	@$(PIP) install wheel $(PIP_EXTRA_OPTS)
	@if [ $$? -ne 0 ]; then echo ">>> deleting virtualenv"; fi

# trying to install directly from wheels
# if fails, download them and try again
# it avoids crawling 
devlibs: venv $(VIRTUALENV_PATH)$(PYTHON_SITE_REL)/devlibs 
$(VIRTUALENV_PATH)$(PYTHON_SITE_REL)/devlibs: requirements.txt 
	@echo ">>> installing dev libs from wheels"
	$(PIP) install --use-wheel --no-index --find-links=$(WHEEL_PATH) -r requirements.txt; \
	if [ $$? -ne 0 ]; then \
		echo "wheel packages not found, downloading them"; \
		$(PIP) wheel -w $(WHEEL_PATH) --no-use-wheel $(PIP_EXTRA_OPTS) -r requirements.txt; \
		$(PIP) install --use-wheel --no-index --find-links=$(WHEEL_PATH) -r requirements.txt; \
	fi
	@if [ $$? -eq 0 ]; then \
		touch $(VIRTUALENV_PATH)$(PYTHON_SITE_REL)/devlibs; fi

# the rpm recreates the virtualenv in another path (RPM_BUILD_ROOT)
# libs should be on that place
# testlibs are not needed
build-libs: devlibs
	# this will copy the site-packages of virtualenv 
	# copy processed pth to dest site-packages 
	@echo ">>> installing libs to lib deploy"
	@mkdir -p $(RPM_BUILD_ROOT)$(SITEPACKAGES_PATH)
	@cp -r $(VIRTUALENV_PATH)$(PYTHON_SITE_REL)/* $(RPM_BUILD_ROOT)$(LIB_DIR)
	@rm -Rf $(RPM_BUILD_ROOT)$(LIB_DIR)/pip
	@rm -Rf $(RPM_BUILD_ROOT)$(LIB_DIR)/pip-*
	@rm -Rf $(RPM_BUILD_ROOT)$(LIB_DIR)/setuptools
	@rm -Rf $(RPM_BUILD_ROOT)$(LIB_DIR)/setuptools-*

install: build-libs
	# this will install source code to dest folder and create running script
	# it generates a pth file with the source code of the app to be deployed
	# into site-packages
	echo ">>> Installing source distribution..."
	@mkdir -p $(RPM_BUILD_ROOT)$(SITEPACKAGES_PATH) $(HOME_DIR)/bin/
	
	sed s:"^#\!.*/bin/python":"#\!/usr/bin/$(PYTHON_INSTALLABLE)":g $(VIRTUALENV_PATH)/bin/devpi-server >$(HOME_DIR)/bin/devpi-server
	chmod 755 $(HOME_DIR)/bin/devpi-server
	@echo "import site; site.addsitedir('$(LIB_DIR)')" > $(RPM_BUILD_ROOT)$(SITEPACKAGES_PATH)/$(NAME).pth

rpm:
	@echo ">>> Generating RPM for version $(VERSION)-$(RELEASE)"
	@dp_package.sh
	@echo

buildci: distclean tests pylint rpm

deployci: buildci
	#Publish only python component, the rpm has been already published after
	# creation.
	@if [ "$(STABLE_BUILD)" == "true" ]; then \
		dp_publish.sh \
	;fi 

devclean: 
	@echo ">>> Removing dev virtualenv..."
	rm -rf $(VIRTUALENV_PATH)
	
distclean: devclean
	@echo ">>> Cleaning all..."
	rm -f $(LIB_ENV_FILE)
	rm -f tags
	rm -rf $(TARGET_DIR) $(METRICS_FILE)
	

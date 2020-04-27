
%define package_name devpi-server
%define modify_package_name true
%define devpi_repo /var/develenv/repositories


%define cdn_home /opt/ss/develenv/platform/
%define installdir %{cdn_home}/devpi-server
%define libdir %{installdir}/lib
%define bindir %{installdir}/bin

Summary:    reliable private and pypi.python.org caching server
Name:       devpi-server
Version:    %{versionModule}
Release:    5.4.1.%{releaseModule}
BuildRoot:  %{_topdir}/BUILDROOT
Prefix:     %{_prefix}
License:    http://opensource.org/licenses/MIT
Packager:   softwaresano.com
Vendor:     softwaresano.com
Group:      develenv
BuildArch:  x86_64
AutoReq:    no
Requires:   python%{python3_version_nodots} ss-develenv-devpi-client ss-develenv-user >= 33 httpd

%description
%{summary}

%install
mkdir -p $RPM_BUILD_ROOT/%{bindir} $RPM_BUILD_ROOT/%{libdir} 

cd %{_srcrpmdir}/..
make devclean
cp -r %{_sourcedir}/* $RPM_BUILD_ROOT/
make install HOME_DIR=$RPM_BUILD_ROOT/%{installdir} RPM_BUILD_ROOT=$RPM_BUILD_ROOT LIB_DIR=%{libdir} SITEPACKAGES_PATH=%{python3_sitearch}
mkdir -p $RPM_BUILD_ROOT/%{devpi_repo}
# ------------------------------------------------------------------------------
# POST-INSTALL
# ------------------------------------------------------------------------------
%post
if [[ "$(sestatus -b|awk '{print $1$2}'|grep 'httpd_can_network_connectoff')" != "" ]]; then \
  setsebool -P httpd_can_network_connect true
fi
systemctl daemon-reload
systemctl try-restart httpd
systemctl try-restart develenv-devpi

%preun
if [ "$1" = 0 ] ; then
    # if this is uninstallation as opposed to upgrade, delete the service
    systemctl stop develenv-devpi > /dev/null 2>&1
    systemctl disable develenv-devpi > /dev/null 2>&1
    exit 0
fi

%clean
rm -rf $RPM_BUILD_ROOT

%files
%defattr(-,root,root)
%{installdir}
%{libdir}
%{bindir}
%{python3_sitearch}/%{package_name}.pth
/etc/httpd/conf.d/*
/etc/systemd/system/*
/etc/sysconfig/*
%defattr(-,develenv,develenv)
%dir %{devpi_repo}
%doc ../../../../README.md

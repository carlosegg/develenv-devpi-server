#!/bin/bash
source /etc/sysconfig/develenv-devpi
echo "[INFO] Initializing devpi repository"
PYTHON_VERSION=$(python --version 2>&1|awk '{print $2}'|cut -d'.' -f1,2) 
export PYTHONPATH=$DEVPI_HOME/lib/python${PYTHON_VERSION}/site-packages/
DEVPI_COMMAND="${DEVPI_HOME_CLIENT}/bin/devpi"
$DEVPI_COMMAND use http://localhost:${DEVPI_LISTEN_PORT}
$DEVPI_COMMAND login root --password ''
$DEVPI_COMMAND user -m root password=temporal
$DEVPI_COMMAND logoff
$DEVPI_COMMAND user -c develenv password=develenv email=develenv@softwaresano.com
$DEVPI_COMMAND login develenv --password=develenv
$DEVPI_COMMAND index -c dev
$DEVPI_COMMAND use develenv/dev
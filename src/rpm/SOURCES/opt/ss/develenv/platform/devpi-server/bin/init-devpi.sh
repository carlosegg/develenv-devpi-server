#!/bin/bash
source /etc/sysconfig/develenv-devpi
echo "[INFO] Initializing devpi repository"
PYTHON_VERSION=$(python3 --version 2>&1|awk '{print $2}'|cut -d'.' -f1,2) 
export PYTHONPATH=$DEVPI_CLIENT_HOME/lib
DEVPI_COMMAND="${DEVPI_CLIENT_HOME}/bin/devpi"
$DEVPI_COMMAND use http://localhost:${DEVPI_LISTEN_PORT}
$DEVPI_COMMAND login root --password ''
$DEVPI_COMMAND user -m root password=temporal
$DEVPI_COMMAND logoff
$DEVPI_COMMAND user -c develenv password=develenv email=develenv@softwaresano.com
$DEVPI_COMMAND login develenv --password=develenv
$DEVPI_COMMAND index -c dev bases=/root/pypi
$DEVPI_COMMAND use develenv/dev
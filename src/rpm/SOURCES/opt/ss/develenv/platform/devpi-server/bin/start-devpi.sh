#!/bin/bash
source /etc/sysconfig/develenv-devpi
if [ "$(ls -al ${DEVPI_REPO_HOME}/|wc -l|grep ^3)" != "" ]; then
   initialize=--init
   logger -p info "devpi server has been initialize"
else
   initialize=""
fi
[[ "$initialize" != "" ]] && ${DEVPI_SERVER_HOME}/bin/devpi-init --serverdir  ${DEVPI_REPO_HOME} --root-passwd ''
${DEVPI_SERVER_HOME}/bin/devpi-server --host=${DEVPI_LISTEN_HOST} \
  --port=${DEVPI_LISTEN_PORT} --outside-url=http://${DEVPI_HOSTNAME}/devpi \
--serverdir ${DEVPI_REPO_HOME} --start

if [[ "$initialize" != "" ]]; then
  ${DEVPI_SERVER_HOME}/bin/init-devpi.sh
fi
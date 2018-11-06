#!/bin/bash
#
# wlsforms startup script for Forms12 Weblogic
#
# (c) 2018 Trivadis GmbH (SOB)
#
# chkconfig: 2345 55 15
# description: forms weblogic start stop
# processname: WLSFORMS
# Source function library
. /etc/rc.d/init.d/functions

ORACLE_USER=oracle
SCRIPT=/u00/app/oracle/tvdtoolbox/tvdwls/FormsStartStop.sh

case "$1" in
start)
  su - ${ORACLE_USER} -c "${SCRIPT} start 2>/dev/null"
  ;;
stop)
  su - ${ORACLE_USER} -c "${SCRIPT} stop 2>/dev/null"
  ;;
status)
  su - ${ORACLE_USER} -c "${SCRIPT} status 2>/dev/null"
  ;;
esac

exit $?

# [root][forms02/-][/etc]:$ find . -name '*oracle_forms*'
# ./rc.d/init.d/oracle_forms
# ./rc.d/rc0.d/K15oracle_forms
# ./rc.d/rc1.d/K15oracle_forms
# ./rc.d/rc2.d/S55oracle_forms
# ./rc.d/rc3.d/S55oracle_forms
# ./rc.d/rc4.d/S55oracle_forms
# ./rc.d/rc5.d/S55oracle_forms
# ./rc.d/rc6.d/K15oracle_forms


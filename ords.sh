#! /bin/bash
# description: Oracle auto start-stop script.
#
# Set ORACLE_HOME to be equivalent to the $ORACLE_HOME
# from which you wish to execute ords;
#
# Set ORA_OWNER to the user id of the owner of the
# Oracle database in ORACLE_HOME.
######################################################
#set -x

ORDS_HOME=${ORACLE_BASE}/product/ords
ORDS=${ORDS_HOME}/bin/ords
ORDS_CONF=${ORDS_HOME}/conf
ORDSLOG=${ORDS_HOME}/logs/ords.log
ORA_OWNER=oracle
JAVA=(which java)
NOHUP=$(which nohup)

function get_ords_process () {
  ORDSPRC=$(ps -ef | grep ords.war|grep -v grep | awk '{print $2}');
  echo ${ORDSPRC}
}

[ -z ${1} ] && {
    echo "Usage: `basename $0` [ start | stop ]"
    exit 1
} || {
case "$1" in
'start')
    # Start the Oracle RESTful Data Service:
    # The following command assumes that the oracle login
    _ORDSP=$(get_ords_process)
    if [[ "$_ORDSP" = "" ]]; then
      export JAVA_OPTIONS="-Dorg.eclipse.jetty.server.Request.maxFormContentSize=3000000"
      #${NOHUP} ${JAVA} ${JAVA_OPTIONS} -jar ords.war standalone >> ${ORDSLOG} 2>&1 &
      ${NOHUP} ords --config ${ORDS_CONF} --java-options ${JAVA_OPTIONS} serve >> ${ORDSLOG} 2>&1 &
      echo "$(date) Started ORDS by $0." | tee -a ${ORDSLOG}
    else
      $0 status
    fi
    ;;
'stop')
    # Stop the Oracle RESTful Data Service:
    # The following command assumes that the oracle login
    _ORDSP=$(get_ords_process)
    if [[ "${_ORDSP}" != "" ]]; then
      echo -n "`date` Stopping ORDS..." | tee -a ${ORDSLOG}
      kill -9 ${_ORDSP} >/dev/null;
      if [[ $? -eq 0 ]]; then
        echo "done" | tee -a ${ORDSLOG}
      else
        echo "failed!" | tee -a ${ORDSLOG}
      fi
        echo "`date` ORDS Stopped by $0" | tee -a ${ORDSLOG}
    else
      echo "`date` ORDS not running ***"  | tee -a ${ORDSLOG}
      exit 1;
    fi
    ;;
'status')
    _ORDSP=$(get_ords_process)
    if [[ "${_ORDSP}" != "" ]]; then
      echo "`date` ORDS is running with pid: ${_ORDSP}" | tee -a ${ORDSLOG}
      exit 0;
    else
      echo "`date` ORDS not running ***" | tee -a ${ORDSLOG}
      exit 1;
    fi
    ;;
'*')
    echo "Usage: `basename $0` [ start | stop ]"
    ;;
esac
}

exit ${?}

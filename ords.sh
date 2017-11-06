#! /bin/sh
# description: Oracle auto start-stop script.
#
# Set ORACLE_HOME to be equivalent to the $ORACLE_HOME
# from which you wish to execute ords;
#
# Set ORA_OWNER to the user id of the owner of the
# Oracle database in ORACLE_HOME.
######################################################
#set -x

ORDS_HOME=/u01/app/oracle/ords
ORDSLOG=${ORDS_HOME}/logs/ords.log
ORA_OWNER=oracle
JAVA=`which java`
NOHUP=`which nohup`
ORDS=`ps -ef | grep ords.war|grep -v grep | awk '{print $2}'`;

 [ x"$1" = x"" ] && {
    echo "Usage: `basename $0` [ start | stop ]"
    exit 1
} || {
case "$1" in
'start')
    # Start the Oracle RESTful Data Service:
    # The following command assumes that the oracle login
    if [[ "$ORDS" = "" ]]; then
      cd ${ORDS_HOME}
      export JAVA_OPTIONS="-Dorg.eclipse.jetty.server.Request.maxFormContentSize=3000000"
      ${NOHUP} ${JAVA} ${JAVA_OPTIONS} -jar ords.war standalone >> ${ORDSLOG} 2>&1 &
      echo "`date` Started ORDS by $0." | tee -a ${ORDSLOG}
    else
      $0 status
    fi
    ;;
'stop')
    # Stop the Oracle RESTful Data Service:
    # The following command assumes that the oracle login
    ORDS=`ps -ef | grep ords.war|grep -v grep | awk '{print $2}'`;
    if [[ "$ORDS" != "" ]]; then
      echo -n "`date` Stopping ORDS..." | tee -a ${ORDSLOG}
      kill -9 ${ORDS} >/dev/null;
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
    if [[ "$ORDS" != "" ]]; then
      echo "`date` ORDS is running with pid: ${ORDS}" | tee -a ${ORDSLOG}
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

exit $?

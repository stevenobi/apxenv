
#!/bin/bash
#
# wlsforms startup script for Forms12 Weblogic
#
# (c) 2018 Trivadis GmbH (SOB)
#
# chkconfig: chkconfig: 2345 55 15
# description: weblogic
# processname: WLSFORMS
# Source function library
. /etc/rc.d/init.d/functions

set +x

[[ ! -z $2 ]] && PRC=`echo "$2"`|| PRC="ALL"

[[ ! -z $DOMAIN_HOME ]]  && export BIN=$DOMAIN_HOME/bin || {
   echo "`date` DOMAIN_HOME is not set. Please set the environment first.";
   exit 1;
 }

## nohup to start weblogic instances
NOHUP=`which nohup`;

## tee for logfile output
TEE=`which tee`;

## Wait Timeout for ADMIN Server Start
SLEEP=10;

## Port on which Weblogic Admin Server listens on (Default for HTTP: 7002)
WLS_ADMIN_PORT=`cat $DOMAIN_HOME/config/config.xml|grep -v grep|grep listen-port|cut -d\> -f2|cut -d\< -f1|head -1`
[[ ! -z $WLS_ADMIN_PORT ]] || WLS_ADMIN_PORT=7002;

## Port on which Oracle HTTP Server listens on (Default for HTTP: 7777)
OHS_PORT=`cat $DOMAIN_HOME/config/fmwconfig/components/OHS/ohs/httpd.conf | egrep ^Listen|cut -d\  -f2`
[[ ! -z $OHS_PORT ]] || OHS_PORT=7777;

## This Script
prog=`basename $0`;

## This Logfile
LOG=$BIN/FORMS12_StartStop.log

################################################################################
# Helper Functions

usage() {
 echo "Usage: $prog {start [service] | stop [service] | status [service] | help}"
}

check_result() {
    if [ ! -z ${1} ]
    then
        [[ ${1} -eq 0 ]] && echo "OK" || echo "ERROR [Code: ${1}]";
    else
        echo "`date` *** ERROR: Null Returncode ***"
    fi
}

check_status() {
    if ([ ! -z ${1} ] &&  [ ! -z ${2} ])
    then
        if [ ${1} -gt 0 ]
        then
            echo "`date` ${2} is running with ${1} process"
        else
            echo "`date` ${2} is not running! -1"
        fi
    else
        echo "`date` *** ERROR: Missing mandatory parameter to check status 1: [$1] , 2: [$2] ***"
    fi
}

### Setting Process Status Variables (should return at least 1 for each process)
WLADM=`ps -ef|grep -v grep| grep java|grep Dweblogic\.Name\=AdminServer|wc -l` >/dev/null;
WLFRM=`ps -ef|grep -v grep| grep java|grep WLS_FORMS|wc -l` >/dev/null;
WLREP=`ps -ef|grep -v grep| grep java|grep WLS_REPORTS|wc -l` >/dev/null;
WLNM=`ps -ef|grep -v grep| grep java|grep nodemanager|wc -l` >/dev/null;
REPS=`ps -ef|grep -v grep| grep java|grep Dcomponent.name=repsrv1|wc -l` >/dev/null;
OHS=`netstat -natp 2>/dev/null |grep -v grep|grep $OHS_PORT|grep LISTEN|wc -l` >/dev/null;

### Weblogic Admin Server (needs to be fully started, so check LISTEN Port)
WLADMS=`netstat -natp 2>/dev/null|grep ::1:${WLS_ADMIN_PORT}|grep LISTEN|grep -v grep|wc -l` >/dev/null;

################################################################################
## Process Arrays
WLS_PROCS=($WLNM $WLADM $WLFRM $WLREP $REPS $OHS);
WLS_PROCS_STOP=($OHS $REPS $WLREP $WLFRM $WLADM $WLNM);
WLS_PROC_NAMES=('WLNM' 'WLS_ADMIN' 'WLS_FORMS' 'WLS_REPORTS' 'REPS' 'OHS');
WLS_PROC_NAMES_STOP=('OHS' 'REPS' 'WLS_REPORTS' 'WLS_FORMS' 'WLS_ADMIN' 'WLNM');

################################################################################
### Process Start Commands

## Generic Call
start_PROCESS() {
    START_CMD="start_${1}";
    [[ ${2} -eq 0 ]] && {
        echo -n "`date` Starting ${1}..." | ${TEE} -a ${LOG}
        ${START_CMD} && RET=`echo $?` && sleep $SLEEP
        check_result ${RET} | ${TEE} -a ${LOG};
    } || {
        echo "`date` ${1} is RUNNING already! Need to stop it first." | ${TEE} -a ${LOG}
        #$0 status ${1};
    }
}


start_WLNM() {
    # Forms Nodemanager
    $NOHUP $BIN/startNodeManager.sh > \
    $DOMAIN_HOME/nodemanager/nodemanager.nohup.out \
    2> $DOMAIN_HOME/nodemanager/nodemanager.nohup.err &
}

start_WLS_ADMIN() {
    # Admin Server
    $NOHUP $BIN/startWebLogic.sh > \
    $DOMAIN_HOME/servers/AdminServer/logs/AdminServer.nohup.out \
    2> $DOMAIN_HOME/servers/AdminServer/logs/AdminServer.nohup.err &
    echo
    while [ `netstat -natp 2>/dev/null|grep ::1:${WLS_ADMIN_PORT}|grep LISTEN|grep -v grep|wc -l` -eq 0 ] 2>/dev/null
    do
        echo "`date` *** Waiting for Weblogic Admin Server to Start ***"
        sleep $SLEEP
    done
}

start_WLS_FORMS() {
    # Forms Weblogic Forms Server
    $NOHUP $BIN/startManagedWebLogic.sh WLS_FORMS > \
    $DOMAIN_HOME/servers/WLS_FORMS/logs/WLS_FORMS.nohup.out \
    2> $DOMAIN_HOME/servers/WLS_REPORTS/logs/WLS_REPORTS.nohup.err &
}

start_WLS_REPORTS() {
    # Forms Weblogic Reports Server
    $NOHUP $BIN/startManagedWebLogic.sh WLS_REPORTS > \
    $DOMAIN_HOME/servers/WLS_REPORTS/logs/WLS_REPORTS.nohup.out \
    2> $DOMAIN_HOME/servers/WLS_REPORTS/logs/WLS_REPORTS.nohup.err &
}

start_REPS() {
    # Report Server
    $BIN/startComponent.sh repsrv1 > $BIN/repsrv1.log
}

start_OHS() {
    # Oracle HTTP Server
    $BIN/startComponent.sh ohs > $BIN/ohs.log
}


################################################################################
### Process Stop Commands

## Generic Call
stop_PROCESS() {
    STOP_CMD="stop_${1}";
    [[ ${2} -gt 0 ]] && {
        echo -n $"`date` Stopping ${1}..."  | ${TEE} -a ${LOG}
        ${STOP_CMD} && RET=`echo $?` && sleep $SLEEP
        check_result ${RET} | ${TEE} -a ${LOG}
    } || {
        echo "`date` ${1} is not RUNNING! Need to start it first."  | ${TEE} -a ${LOG}
        #${0} status ${1};
    }
}

stop_WLNM() {
    # Forms Nodemanager
    $BIN/stopNodeManager.sh >> \
    $DOMAIN_HOME/nodemanager/nodemanager.nohup.out \
    2>> $DOMAIN_HOME/nodemanager/nodemanager.nohup.err &
}

stop_WLS_ADMIN() {
    # Admin Server
    $BIN/stopWebLogic.sh >> \
    $DOMAIN_HOME/servers/AdminServer/logs/AdminServer.nohup.out \
    2>> $DOMAIN_HOME/servers/AdminServer/logs/AdminServer.nohup.err &
}

stop_WLS_FORMS() {
    # Forms Weblogic Forms Server
    $BIN/stopManagedWebLogic.sh WLS_FORMS >> \
    $DOMAIN_HOME/servers/WLS_FORMS/logs/WLS_FORMS.nohup.out \
    2>> $DOMAIN_HOME/servers/WLS_REPORTS/logs/WLS_REPORTS.nohup.err &
}

stop_WLS_REPORTS() {
    # Forms Weblogic Reports Server
    $BIN/stopManagedWebLogic.sh WLS_REPORTS >> \
    $DOMAIN_HOME/servers/WLS_REPORTS/logs/WLS_REPORTS.nohup.out \
    2>> $DOMAIN_HOME/servers/WLS_REPORTS/logs/WLS_REPORTS.nohup.err &
}

stop_REPS() {
    # Report Server
    $BIN/stopComponent.sh repsrv1 >> $BIN/repsrv1.log
}

stop_OHS() {
    # Oracle HTTP Server
    $BIN/stopComponent.sh ohs >> $BIN/ohs.log
}

################################################################################
### Main Commands

## Start
start() {
case "$PRC" in
    "ALL" | "")
        let a=0;
        for p in ${WLS_PROC_NAMES[@]}; do
            ## get process status
            x=${WLS_PROCS[${a}]};
            start_PROCESS  ${p} ${x}
        let a=a+1;
        done
    ;;
    *)
        let a=0;
        for p in ${WLS_PROC_NAMES[@]}; do
          ## check if arg1 is in process list
          if [ ${PRC} == ${p} ]
          then
            ## get process status
            x=${WLS_PROCS[${a}]};
            start_PROCESS  ${p} ${x}
          fi
        let a=a+1;
        done
        [[ ${a} -eq 0 ]] && echo "`date` *** Invalid Process ${PRC}!"
    ;;
esac
}

## Stop
stop() {
case "$PRC" in
    "ALL" | "")
        let a=0;
        for p in ${WLS_PROC_NAMES_STOP[@]}; do
            ### get process status
            x=${WLS_PROCS_STOP[${a}]};
            stop_PROCESS ${p} ${x}
        let a=a+1;
        done
    ;;
    *)
        let a=0;
        for p in ${WLS_PROC_NAMES_STOP[@]}; do
            ## check if arg1 is in process list
            if [ ${PRC} == ${p} ]
            then
              ## get current status for process
              x=${WLS_PROCS_STOP[${a}]};
              stop_PROCESS ${p} ${x}
            fi
        let a=a+1;
        done
        [[ ${a} -eq 0 ]] && echo "`date` *** Invalid Process ${PRC}!"
    ;;
esac
}

## Status
status() {
    case "${PRC}" in
    "ALL" | "")
        let a=0;
        for p in ${WLS_PROC_NAMES[@]}; do
          ## get current status for process
          x=${WLS_PROCS[${a}]};
          check_status ${x} ${p}
        let a=a+1;
        done
    ;;
    *)
        let a=0;
        for p in ${WLS_PROC_NAMES[@]}; do
          ## check if arg1 is in process list
          if [ ${PRC} == ${p} ]
          then
            ## get current status for process
            x=${WLS_PROCS[${a}]};
            check_status ${x} ${p}
          fi
        let a=a+1;
        done
        [[ ${a} -eq 0 ]] && echo "`date` *** Invalid Process ${PRC}!"
    ;;
    esac
}


###############################################################################
## Script Call
case "$1" in
start)
  start
  ;;
stop)
  stop
  ;;
status)
  status
  ;;
help)
  echo "" && usage
  echo "" && echo "Where service is one of the following:" && echo ""
   for i in ${WLS_PROC_NAMES[@]}; do
     echo $i
   done
  echo "" && echo "If no service is provided then ALL services are started/stopped" && echo ""
  ;;
*)
  usage
  exit 1
  ;;
esac

exit $?

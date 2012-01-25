#!/bin/bash
#
##########################################################################################################
#                                                                                                        #
# PID file creating and checking                                                                         #
# exit program if running                                                                                #
#                                                                                                        #
# This script is bundled with cleanupPid.sh                                                              #
#                                                                                                        #
# (c) Jasper Roel                                                                                        #
#                                                                                                        #
##########################################################################################################

##########################
# Settings               #
##########################
PROCESSNAME=`basename $0`
MY_PID=$$
PIDFILE="/var/run/${PROCESSNAME}.pid"

##########################
# Code                   #
##########################
# check for pidfile
if [ -f $PIDFILE ] ; then
	PID=`cat $PIDFILE`
	if [ "x$PID" != "x" ] && kill -0 $PID 2>/dev/null ; then
		STATUS="${PROCESSNAME} (pid $PID) running"
		RUNNING=1
	else
		STATUS="${PROCESSNAME} (pid $PID?) not running, removing stale PID file"
		RUNNING=0
		`rm $PIDFILE`
	fi
else
	STATUS="${PROCESSNAME} (no pid file) not running"
	RUNNING=0
fi

if [ $RUNNING -eq 1 ]; then
	echo "$0 $ARG: ${PROCESSNAME} (pid $PID) already running"
	exit 1;
fi

#create PID file
if [ $RUNNING == 0 ]; then
	echo $MY_PID > $PIDFILE
fi

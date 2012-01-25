#!/bin/sh

##########################################################################################################
#                                                                                                        #
# PID file checking and deletion                                                                         #
#                                                                                                        #
# This script is bundled with checkPid.sh                                                                #
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
if [ -f $PIDFILE ]; then
	rm $PIDFILE
else
	echo "PID for proces $PROCESSNAME ($PIDFILE) missing, not removing"
	exit 1
fi

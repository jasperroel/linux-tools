#!/bin/sh

##########################################################################################################
#                                                                                                        #
# Disk space checker script                                                                              #
#                                                                                                        #
# (c) Jasper Roel                                                                                        #
#                                                                                                        #
##########################################################################################################

##########################
# PID file creating      #
# and checking           #
#                        #
# exit if running        #
##########################
. /root/linux-tools/checkPid.sh

##########################
# Vars                   #
##########################

# Set warning and low limit to 1.0gb and 0.5gb
warninglimit=1000000
lowlimit=500000

# File systems to check
filesystems="/ /var/lib/mysql"

# Settings to keep tmp folder clean
folder="/tmp"
age="2"

##########################
# Code                   #
##########################
# Loop through filesystems
for fs in $filesystems
do
        # Get the remaining space on this filesystem
        size=`df -k $fs|grep $fs|awk '{ print $4; }'`

        if [[ $size -le $lowlimit ]]
        then
			echo "URGENT: Low disk space for $fs ($size) on $HOSTNAME"
			if [ "$fs" = "/nogleeg" ]
			then

				echo "Cleaning out tmp files older than $age hours"
				find $fs$folder/* -amin +$age -exec /bin/rm -rf {} \; 2>/dev/null 1>&2

			fi
        fi

        if [[ $size -le $warninglimit ]]
        then
			echo "WARNING: Low disk space for $fs ($size) on $HOSTNAME"
    	fi
done

##########################
# Cleanup                #
# Unlink PID file        #
##########################
. /root/linux-tools/cleanupPid.sh
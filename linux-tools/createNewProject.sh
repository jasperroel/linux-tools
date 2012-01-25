#!/bin/sh

##########################################################################################################
#                                                                                                        #
# Creeer een nieuw SVN project op Naraht                                                                 #
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
dest=/usr/local/svnroot/
SVN_SERVER="https://** SVN Server here**"

##########################
# Pre-checks             #
##########################

##########################
# Code                   #
##########################
read -p "Project name: " PROJECTNAAM; echo

if [ -z "$PROJECTNAAM" ]
then
	echo 'Please enter a project name.'
	exit 2
fi

`sudo -H -u nobody svnadmin create ${dest}$PROJECTNAAM`
svn mkdir	$SVN_SERVER/$PROJECTNAAM/tags \
			$SVN_SERVER/$PROJECTNAAM/branches \
			$SVN_SERVER/$PROJECTNAAM/trunk \
			-m "Initial import basic folder tags/branches/trunk"

echo "Created project $project_name"

##########################
# Cleanup                #
# Unlink PID file        #
##########################
. /root/linux-tools/cleanupPid.sh
#!/bin/sh

##########################################################################################################
#                                                                                                        #
# Generiek script om servers te backupen naar een van onze fileservers                                   #
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
# Settings               #
##########################

HOSTNAME=`hostname`
BACKUPDIR=`date +%A`

BACKUPSERVER='**Backup server here**'
MYSQLBACKUPDIR='/backups/mysqlbackup'

##########################
# Directories to backup  #
##########################
directories=( )
directories=( ${directories[@]} /var/log/apache /var/log/apache2 /var/log/httpd )
directories=( ${directories[@]} /var/www/websites )
directories=( ${directories[@]} /etc /home /opt )

##########################
# Used arguments         #
##########################

# -a --archive		archive mode; same as -rlptgoD (no -H) *
# -R --relative		use relative path names
# -v --verbose		increase verbosity

# -b --backup		make backups (see --suffix & --backup-dir)
# --backup-dir		make backups into hierarchy based in DIR

# *	The files are transferred in "archive" mode, which ensures that symbolic links, devices, attributes, permissions, ownerships,
#	etc. are preserved in the transfer.

rsync_args='-aRv --no-implied-dirs'

# --delete-during does not work on certain servers, check via man / grep checken if this option exists, otherwise, use "--delete-after"
if [[ -n "`man rsync | grep -- --delete-during`" ]]; then
	rsync_args="$rsync_args --delete-during"
else
	rsync_args="$rsync_args --delete-after"
fi

##########################
# Code                   #
##########################

# backup directories
for d in "${directories[@]}"; do
	if [[ -d "$d" ]]; then
		rsync $rsync_args -b --backup-dir=$BACKUPDIR $d $BACKUPSERVER::$HOSTNAME
	fi
done

# backup MySQL
if [[ -d "$MYSQLBACKUPDIR" ]]; then
	rsync $rsync_args $MYSQLBACKUPDIR $BACKUPSERVER::$HOSTNAME
fi
##########################
# Old stuff...           #
##########################

#if [[ -d /var/log/apache2 ]]; then
#	rsync -aRvb --delete-during --backup-dir=$BACKUPDIR /var/log/apache2 $BACKUPSERVER::$HOSTNAME
#fi
#rsync -aRvb --delete-during --backup-dir=$BACKUPDIR /var/www/websites $BACKUPSERVER::$HOSTNAME
#rsync -aRvb --delete-during --backup-dir=$BACKUPDIR /etc $BACKUPSERVER::$HOSTNAME
#rsync -aRvb --delete-during --backup-dir=$BACKUPDIR /home $BACKUPSERVER::$HOSTNAME
#

##########################
# Cleanup                #
# Unlink PID file        #
##########################
. /root/linux-tools/cleanupPid.sh

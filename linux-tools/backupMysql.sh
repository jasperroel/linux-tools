#!/bin/sh

##########################################################################################################
#                                                                                                        #
# Backup MySQL naar een bepaalde map. Voor backup redenen is deze hard gecodeerd                         #
#                                                                                                        #
# (c) Jasper Roel                                                                                        #
#                                                                                                        #
# Date and time functions: http://www.unix.com/showthread.php?t=31944                                    #
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
suffix=`date +%Y%m%d`
dest=/backups/mysqlbackup
cmd='/usr/bin/mysqldump'
passwd_file="/root/.mypass"

##########################
# Pre-checks             #
##########################

#Root password
if [[ -f "$passwd_file" ]]; then
	passwd=`cat $passwd_file`
	if [[ -z $passwd ]]; then
		echo "File $passwd_file does not exist or is empty"
		exit 1
	fi
else
	echo "File $passwd_file does not exist";
	exit 1
fi

# check existence backupfolder
if [[ ! -d "$dest" ]]; then
	mkdir -p $dest
	if [[ ! -d "$dest" ]]; then
		echo "Creating dir $dest failed"
		exit 1
	fi
fi

##########################
# Code                   #
##########################
# backup
databases=(`echo 'show databases;' | mysql -u root --password=$passwd | grep -v ^Database$`)

for d in "${databases[@]}"; do
	if [[ $d != 'tmp' && $d != 'test' ]]; then
		echo "DATABASE ${d}"
		s="use ${d}; show tables;"
		tables=(`echo ${s} | mysql -u root --password=$passwd | grep -v '^Tables_in_'`)
		for t in "${tables[@]}"; do
			if [[ $t != 'tbl_parameter' && $t != 'tbl_session' ]]; then
				echo " TABLE ${t}"
				path="${dest}/${suffix}/${d}"
				mkdir -p ${path}
				${cmd} --user=root --password=$passwd --quick --add-drop-table --all ${d} ${t} | bzip2 -c > ${path}/${t}.sql.bz2
			fi
		done
	fi
done

# delete old dumps (retain 5 days)
find ${dest} -maxdepth 1 -mtime +5 -type d -exec rm -rf {} \;

##########################
# Cleanup                #
# Unlink PID file        #
##########################
. /root/linux-tools/cleanupPid.sh

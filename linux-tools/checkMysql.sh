#!/bin/bash

##########################################################################################################
#                                                                                                        #
# Script om een server te controleren op fouten in MySQL tabellen.                                       #
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
USER=root
passwd_file="/root/.mypass"
tmp_file=/tmp/cron-mysql.errors
optimize_file=/root/last-gids-optimize
log_file=/var/log/checkMysql.log
optimize_days=7
disable_optimize=1
auto_repair=0

mail_to="** email address here - separated by a space"
mail_from="DB Checker <dbchecker@example.nl>"

# Do not modify anything below...
errors=( )
databases=( )
header_displayed=0
force_optimize=0
DEBUG=0
debug_str=''
# Argument values
NO_ARGS=0
E_OK=0
E_BADARGS=2

##########################
# Includes               #
##########################
. /root/linux-tools/sendMail.sh

##########################
# Functions              #
##########################
# Function 1of3 - date checker
date2stamp () {
    date --utc --date "$1" +%s
}

# Function 2of3 - date checker
stamp2date (){
    date --utc --date "1970-01-01 $1 sec" "+%Y-%m-%d %T"
}

# Function 3of3 - date checker
dateDiff (){
    case $1 in
        -s)   sec=1;      shift;;
        -m)   sec=60;     shift;;
        -h)   sec=3600;   shift;;
        -d)   sec=86400;  shift;;
        *)    sec=86400;;
    esac
    dte1=$(date2stamp $1)
    dte2=$(date2stamp $2)
    diffSec=$((dte2-dte1))
    if ((diffSec < 0)); then abs=-1; else abs=1; fi
    echo $((diffSec/sec*abs))
}
displayHeaders()
{
	local header='';
	if [[ "$header_displayed" == 0 ]]; then
		header="
################## MySQL Checker ######################
#                                                     #
# Created by Jasper Roel                              #
#                                                     #
#######################################################
#Started @ `date`
#######################################################
"
	fi

	header_displayed=1
	echo "$header";
}

displayFooter()
{
	local header="
#######################################################
#Ended @ `date`
#######################################################"
	echo "$header";
}

displayVersion()
{
		echo "Usage: `basename $0` [OPTION]... [DATABASE]..."
		echo 'MySQL database checker'
		echo "Example: `basename $0` -d 'database' -f"
		echo
		echo 'Copyright (C) 2007 Jasper Roel'
		echo 'Version 1.0'
}

debug()
{
	debugstring=$1
	if [[ $DEBUG == 1 ]]; then
		debug_str="$debug_str*DEBUG: $1\n";
	fi
}

show_debug()
{
	if [[ $DEBUG == 1 ]]; then
		echo -e "$debug_str"
		displayHeaders >> $log_file
		echo -e "$debug_str" >> $log_file
		displayFooter >> $log_file
	fi

}
checkargs()
{
	if [ $# -eq "$NO_ARGS" ]; then  # Script invoked with no command-line args?
		displayVersion
		echo
		echo 'Database selection:'
		echo $'  -a, --all-databases\t\t Check all available databases,'
		echo $'\t\t\t\t (except tmp, test and information_schema)'
		echo $'  -d, --database DATABASE\t Check only given database'
		echo
		echo 'Miscellaneous:'
		echo $'  -f, --force-optimize\t\t This is normally done once a week, setting'
		echo $'\t\t\t\t this flag forces optimizing all selected databases'
		echo $'  -D, --debug\t\t\t Enable debug modus'
		echo
		echo $'  -v, --version\t\t\t prints version and exits'
		echo
		echo $"Exit status is $E_OK if no problems, $E_BADARGS if no arguments are given"
		exit $E_BADARGS
	fi

	# Note that we use `"$@"' to let each command-line parameter expand to a
	# separate word. The quotes around `$@' are essential!
	# We need TEMP as the `eval set --' would nuke the return value of getopt.
	TEMP=`getopt -o ad::fDv --long all-databases,force-optimize,database::,version,debug \
		 -- "$@"` # -n 'example.bash'

	# Note the quotes around `$TEMP': they are essential!
	eval set -- "$TEMP"

	while true ; do
    	case "$1" in
	        -a|--all-databases) databases=(`echo 'SHOW DATABASES;' | mysql --user=$USER --password=$passwd | grep -v ^Database$`) ; shift ;;
    	    -f|--force-optimize) force_optimize=1 ; shift ;;
        	-d|--database)
	            # -d has an optional argument. As we are in quoted mode,	Not anymore (: is required, :: is optional
    	        # an empty parameter will be generated if its optional		Comment is here for historical reasons
        	    # argument is not found.
            	case "$2" in
	                "") echo "ERROR: $1 requires a database as argument"; echo; displayVersion; exit 1; shift 2 ;;
    	            *)  databases=( $2 ) ; shift 2 ;;
	            esac ;;
			-D|--debug) DEBUG=1 ; shift ;;
			-v|--version) displayVersion; exit 0; shift ;;
    	    --) shift ; break ;;
	        *) echo "Internal error!" ; exit 1 ;;
	    esac
	done
}


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

# Optimize is normally supposed to be done once every week
# It can be forced by a parameter
# And also be disabled by configuration 
if [[ "$force_optimize" -ne 1 ]]; then
	if [[ -f $optimize_file ]]; then
		MODDATE=$(stat -c %y ${optimize_file})
		MODDATE=${MODDATE%% *}
		daydiff=`dateDiff -d $MODDATE "now"`

		if [[ $daydiff -gt $optimize_days ]]; then
			debug "We are also going to optimize all tables, it has been over a week."
			optimize=1
		else
			debug "We are NOT going to optimize all tables, it has recently been done."
			optimize=0
		fi
	else
		debug "We are also going to optimize all tables, because I cant find the last time we did this."
		optimize=1
	fi
else
	debug "We are also going to optimize all tables, --force-optimize was specified on the command line."
	optimize=1
fi

if [[ "$disable_optimize" -eq 1 ]]; then
	debug "Optimize has been disabled by configuration (disable_optimize=1)"
	optimize=0
fi
##########################
# Code                   #
##########################
debug displayHeaders;

checkargs $*

for d in "${databases[@]}"; do
	debug "Checking Database $d"
	if [[ $d != 'tmp' && $d != 'test' && $d != 'information_schema' ]]; then
		s="USE ${d}; SHOW TABLES;"
		tables=(`echo "${s}" | mysql --user=$USER --password=$passwd | grep -v '^Tables_in_' | sed 's/ /--SPACE--/'`)
		for t in "${tables[@]}"; do
			t=`echo "$t" | sed 's/--SPACE--/ /'`
			debug " Checking table $t for warnings and errors"
			if [[ "$t" != 'tbl_parameter' && "$t" != 'tbl_session' ]]; then
			if [[ "$d" != 'gids' || ("$d" == 'gids'  && ("$t" == 'finetuner' || "$t" == 'temp_search_organisation')) ]]; then
				#This checks the table itself, not the data

				if [[ $optimize == 1 ]]; then
					command="\"OPTIMIZE TABLE ${t};\" "
					result=`mysql --user=$USER --password=$passwd --database=${d} --vertical -v -v -v --execute="OPTIMIZE TABLE "${t}";" | grep -E -e "optimize\W*(error|warning)"` # | cut -f1,4`

					debug "  command : $command"
					debug "  result  :\n$result"

					if [[ -n "$result" ]]; then
						errors=( "${errors[@]}" "$result" )
						debug "ERROR:   added ${d}.${t} to error collection"
					fi
				fi

				#The data itself may be corrupt, select 1 row to be sure
				command="\"SELECT \* FROM ${t} LIMIT 1;\""
				result=`mysql --user=$USER --password=$passwd --database=${d} --vertical -v -v -v --execute="SELECT * FROM ${t} LIMIT 1;" 2>&1 | grep -E -e "ERROR [\d]{0,5}"`

				debug "  command : $command"
				debug "  result  :\n$result"
				if [[ -n "$result" ]]; then
					errors=( "${errors[@]}" "${d}.${t}\n$result" )
					debug "ERROR:   added ${d}.${t} to error collection"
				fi
			fi
			fi
		done
	fi
done

#If we optimized MySQL, we have to reset the counter
if [[ $optimize == 1 ]]; then touch $optimize_file; fi

debug "${#errors[*]} Error(s) found"
for e in "${errors[@]}"; do
	message='';
	echo "$e" >  $tmp_file
	db=`cut -f1  $tmp_file`
	er=`cut -f2- $tmp_file`

	echo "$db" > $tmp_file
	db=`cut -f1 -d. $tmp_file`
	tb=`cut -f2 -d. $tmp_file`

	mail_subject="Database checker - ${#errors[*]} Error(s) found"

	message="$message\n"

	message="$message\n${#errors[*]} error(s) found:"
	message="$message\n#######################################################"
	message="$message\nDatabase: $db"
	message="$message\nTable: $tb"
	message="$message\nFout: $er"
	message="$message\n"
	command="REPAIR TABLE \`${tb}\`;\""
	message="$message\nQuery: $command"
	if [[ "$auto_repair" -eq 1 ]]; then
		message="$message\nRepair result:"
		result=`mysql --user=$USER --password=$passwd --database=${d} --vertical -v -v -v --execute="REPAIR TABLE ${tb};"`
		message="$message\n$result"
	else
		message="$message\n\nDid NOT automatically repair (auto_repair=0), you need to do this manually!\n"
	fi
	message="$message\n#######################################################"

	send_mail "$mail_to" "$mail_subject" "$message" "$mail_from";
	echo -e "$message" >> $log_file
done

show_debug;

##########################
# Cleanup                #
# Unlink PID file        #
##########################
. /root/linux-tools/cleanupPid.sh
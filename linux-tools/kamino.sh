#!/bin/sh

##########################################################################################################
#                                                                                                        #
# Kamino [http://starwars.wikia.com/wiki/Kamino]                                                         #
# A first attempt to use inotify integrated into SVN                                                     #
#                                                                                                        #
# (c) Jasper Roel 2008                                                                                   #
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
DEBUG_TO_PROMPT=false
DEBUG_TO_FILE=true
DEBUG_LOGFILE=/var/log/kamino_debug

WATCH_DIR="/root/testing"
WATCH_EVENTS="CLOSE_WRITE CREATE DELETE MOVE" #  DELETE_SELF MOVE_SELF
WATCH_LOG=/var/log/kamino_log
WATCH_IGNORE=".svn"

SVN_ROOT="https://**SVN Server here**/**SVN Project here**/trunk"

# TODO (instead of hardcoded values. Would be cool right?)
CONFIG_FILE=''
##########################
# Vars                   #
##########################

# Default vars
header_displayed=0
start_time=`date`

events=''
dir_moved_from=''
file_moved_from=''

EXIT_NO_ARGS=0
EXIT_OK=0
EXIT_BADARGS=2

##########################
# Functions              #
##########################
debug()
{
	DEBUG_STRING="$1";

	[ ${DEBUG_TO_PROMPT} == true ] && debug_print "${DEBUG_STRING}" ;
	[ ${DEBUG_TO_FILE} == true ] && debug_log "${DEBUG_STRING}" ;
}

debug_print()
{
	echo -e "$1"
}
debug_log()
{
		echo -e "$1" >> ${DEBUG_LOGFILE}
}

displayHeader()
{
	local header='';
	if [ "${header_displayed}" == '0' ]; then
		header="
################## Kamino #############################
#                                                     #
# Created by Jasper Roel                              #
#                                                     #
#######################################################
#Started @ ${start_time}
#######################################################"
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

displayOptions()
{
	echo "
Options:
  -d, --debug        Enable debug modus
  -c, --config-file  Point to location of the config file
  -v, --version      Prints version and exits

Exit status is $EXIT_OK if no problems, $EXIT_BADARGS if no arguments are given"
}

displayVersion()
{
		echo "Usage: `basename $0` [OPTION]..."
		echo 'Kamino'
		echo "Example: `basename $0`"
		echo
		echo 'Copyright (C) 2008 Jasper Roel'
		echo 'Version 1.0'
}

checkargs()
{

	## "No arguments" is also accepted
	#	if [ "$#" -eq "$EXIT_NO_ARGS" ]; then  # Script invoked with no command-line args?
	#		displayVersion
	#		displayOptions
	#		exit $EXIT_BADARGS
	#	fi

	# Note that we use `"$@"' to let each command-line parameter expand to a
	# separate word. The quotes around `$@' are essential!
	# We need TEMP as the `eval set --' would nuke the return value of getopt.

	# : argument is required, :: argument is optional
	TEMP=`getopt -o dc::v --long debug,config-file::,version -- "$@"`

	# Note the quotes around `$TEMP': they are essential!
	eval set -- "$TEMP"

	while true ; do
    	case "$1" in
			-d|--debug) DEBUG_TO_PROMPT=true ; shift ;;
    		-c|--config-file) # Required argument (the file)
            	case "$2" in
	                "") echo "ERROR: $1 requires a file as argument"; echo; displayVersion; exit $EXIT_BADARGS ;;
    	             *) config_file=$2 ; shift 2 ;;
    			esac ;;
			-v|--version) displayVersion ; exit $EXIT_OK ;;
    	    --) shift ; break ;;
	        *) echo "Internal error!" ; exit $EXIT_BADARGS ;;
	    esac
	done
}
##########################
# Code                   #
##########################
checkargs $*

debug "$( displayHeader )"

for watch_event in ${WATCH_EVENTS} ; do
	events="${events} -e ${watch_event}"
done

for ignore_item in ${WATCH_IGNORE} ; do
	ignore="${ignore} --exclude ${ignore_item}"
done


debug "Watching directory: '${WATCH_DIR}'"
debug "Watching for these events: '${WATCH_EVENTS}'"

inotifywait -mrq --timefmt '%d/%m/%y %H:%M' --format '%T "%f" "%w" %e' \
${ignore} ${events} ${WATCH_DIR} | while read date time file folder event; do

	# Filter out the static vars (we need these in case one of the is empty)
#	file=${file:5}       # Filter out the "FILE prefix & " postfix
#	folder=${folder:7}   # Filter out the "FOLDER prefix & " postfix
#	event=${event:5}     # Filter out the EVENT prefix

	# Postfix filter
#	filelen=${#file}-1
#	file=${file:1:${filelen}}

#	folderlen=${#folder}-1
#	folder=${folder:1:${folderlen}}
	debug "date:   $date\ntime:   $time\nfile:   $file\nfolder: $folder\nevent:  $event"

	# Default values
	type='unknown'
	action='accessed'

	path="${folder}${file}"
	rel_path=${path:${#WATCH_DIR}}

	# SVN integration
	svn_commit=false
	svn_up=false

	# MOVED_FROM && MOVED_TO have gone before this one, ignoring these, they add nothing to the process
	# IGNORED can be (what's in a name..) ignored 
	[[ "${event}" == 'MOVE_SELF' || 
 	   "${event}" == 'DELETE_SELF' ||
 	   "${event}" == 'IGNORED' ||
	   "${event}" == '' ]] &&  continue

	# Deletings occur BEFORE inotify is triggered, processing these before any type checking
	[ "${event}" == 'DELETE,ISDIR' ] && type='folder' ;	# Folder deletion
	[ "${event}" == 'DELETE' ] && type='file' ;         # File deletion

	[ -d "${path}" ] && type='folder'
	[ -f "${path}" ] && type='file'

	# folder movement [step 1of2]
	if [ "${event}" == 'MOVED_FROM,ISDIR' ]; then
		dir_moved_from="${path}"
		dir_moved_from_rel="${path:${#WATCH_DIR}}"
		continue
	fi

	# file movement [step 1of2]
	if [ "${event}" == 'MOVED_FROM' ]; then
		file_moved_from="${path}"
		file_moved_from_rel="${path:${#WATCH_DIR}}"
		continue
	fi

	# Don't know what it is, so lets keep it that way
	[ "${type}" == 'unknown' ] && debug "unknown - breaking because of events: ${event} for path: ${path}" && continue

	############## Directory functions ##############

	# New folder creation
	if [ "${event}" == 'CREATE,ISDIR' ]; then
		action='created'

		# SVN integration
		debug "svn add --non-recursive ${path}"
		svn add --non-recursive "${path}"
		svn_commit=true
		svn_up=true
	fi

	# folder movement [step 2of2]
	if [ "${event}" == 'MOVED_TO,ISDIR' ]; then
		#should be available: ${dir_moved_from}
		dir_moved_to="${path}"
		action="moved from ${dir_moved_from}"
		dir_moved_from='' # Blank it again

		# SVN integration
		debug "svn delete --force ${SVN_ROOT}${dir_moved_from_rel} -m Server side folder delete (reflecting folder move)" 
		svn delete --force "${SVN_ROOT}${dir_moved_from_rel}" -m "Server side folder delete (reflecting folder move)"
		#remove all .svn folders
		rm -rf `find ${dir_moved_to} -type d -name .svn`
		# SVN add it again
		svn add --force --non-recursive "${dir_moved_to}"
		svn_commit=true
		svn_up=true
	fi

	# Folder deletion (NOTE: The folder itself is already gone!)
	if [ "${event}" == 'DELETE,ISDIR' ]; then
		action='deleted'

		# SVN integration
		debug "svn delete ${SVN_ROOT}${rel_path} -m Server side folder delete (reflecting real delete)"
		svn delete "${SVN_ROOT}${rel_path}" -m "Server side folder delete (reflecting real delete)"
		svn_up=true
	fi

	############## File functions ##############

	# New file creation
	if [ "${event}" == 'CREATE' ]; then
		action='created'

		# SVN integration
		svn add "${path}"
		svn_commit=true
		svn_up=true
	fi

	# file movement [step 2of2]
	if [ "${event}" == 'MOVED_TO' ]; then
		#should be available: ${file_moved_from}
		file_moved_to="${folder}${file}"
		action="moved from ${file_moved_from}"
		file_moved_from='' # Blank it again

		# SVN integration
		svn move --force "${SVN_ROOT}${dir_moved_from_rel}" "${SVN_ROOT}${rel_path}" -m "Server side file move (reflecting real move)"
		svn_up=true
	fi

	# File deletion  (NOTE: The file itself is already gone!)
	if [ "${event}" == 'DELETE' ]; then
		action='deleted'
		type='file'

		# SVN integration
		svn delete "${SVN_ROOT}${rel_path}" -m "Server side file delete (reflecting real delete)"
		svn_up=true
	fi

	# Existing file saved
	if [ "${event}" == 'CLOSE_WRITE,CLOSE' ]; then
		action="saved"
	fi

	############## SVN cleanup #################
	if [ ${svn_up} == true ]; then
		if [ "${type}" == 'folder' ]; then
			total=${#path}
			base=`basename ${path}`
			strip=${total}-${#base}-1
			parent_folder=${path:0:${strip}}

#			debug "total:          ${total}"
#			debug "base:           ${base}"
#			debug "strip:          ${strip}"
#			debug "path:           ${path}"
#			debug "parent folder:  ${parent_folder}"

			svn up --non-interactive --non-recursive "${parent_folder}"
			svn up --non-interactive "${parent_folder}"

#			svn up --non-interactive --non-recursive "${path}"
#			svn up --non-interactive "${path}"

		fi
		[ "${type}" == 'file' ] && svn up --non-interactive "${path}"
	fi

	if [ ${svn_commit} == true ]; then
		[ "${type}" == 'folder' ] && svn commit --non-interactive "${WATCH_DIR}" -m "kamino forced commit"
		[ "${type}" == 'file' ] && svn commit --non-interactive "${path}" -m "kamino forced commit"
	fi

	debug "At ${time} on ${date}, ${type} ${folder}${file} was ${action} (EVENTS: ${event})"
done

debug "$( displayFooter )"

##########################
# Cleanup                #
# Unlink PID file        #
##########################
. /root/linux-tools/cleanupPid.sh
#!/bin/bash

##########################################################################################################
#                                                                                                        #
# Script om bepaalde personen een mail te sturen met informatie uit het originele script                 #
#                                                                                                        #
# (c) Jasper Roel                                                                                        #
#                                                                                                        #
##########################################################################################################


##########################
# Vars                   #
##########################
_arr_rec=( )
_str_rec=''

##########################
# Functions              #
##########################

# Verstuur een mailtje met informatie

#########################################
# function call:                        #
# send_mail recipient subject message   #
#                                       #
#########################################

function send_mail() 
{
	local recipients=$1
	local subject=$2
	local message=$3
	local from=$4

	myexplode "," "$recipients"

	for r in "${_arr_rec[@]}"; do
		mail_to="\n\nDeze mail is verzonden naar de volgende e-mail adressen: $_str_rec"

		contents="$message $mail_to"
#		echo -e "$contents" | mail  -s "$subject"  "$r"
		echo -e "Subject:$subject\nFrom:$from\nImportance:High\nTo:$_str_rec\n$contents" | sendmail $r
	done
}

#Importance: High
#X-Priority: 1 (High)

# Function
myexplode () {
	array=`echo $2 | awk "BEGIN{FS=\"$1\";OFS=\"NISSEPISSE\";}{print \\$1,\\$2,\\$3,\\$4,\\$5,\\$6,\\$7}" | sed 's/ /KALLEKOSKIT/g' | sed 's/NISSEPISSE/ /g'`
	i=0
	for ar in $array
	do
		_arr_rec[$i]=`echo "$ar" | sed 's/KALLEKOSKIT/ /g'`
		if [[ -z "$_str_rec" ]]; then
			_str_rec="${_arr_rec[$i]}"
		else
			_str_rec="$_str_rec,${_arr_rec[$i]}"
		fi
		i=`expr $i + 1`
	done
}
# End func

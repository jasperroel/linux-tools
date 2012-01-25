#!/bin/sh

########################################
#
# Bestanden ouder dan een x aantal dagen
# kunnen verwijderd worden.
#
########################################

########################################
#
# Variabelen
#
########################################

# Welke map(pen) moet/moeten in de gaten gehouden worden?
BACKUPDIRS=( /backups/ /nogleeg/ )

# Na hoeveel dagen moeten de bestanden verwijderd worden?
KEEPFILES=3

########################################
#
# Code
#
########################################

for d in "${BACKUPDIRS[@]}"; do
	if [[ -d "$d" ]]; then
		/usr/bin/find $d. -atime +$KEEPFILES -exec rm -rf {} \;
	fi
done

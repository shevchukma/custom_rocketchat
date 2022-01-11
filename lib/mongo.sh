#!/bin/bash

# mongoCommand [str *command] [str *node]
mongoCommand() {

	local errCall="[FAILED]: [Please call: mongoCommand [master/secondary] ]"

	declare -n node=$1
	declare -n mongoCmd=$2

	if [ $debug -eq 1 ]; then debug "$FUNCNAME $@" ; fi
	if [ "$1" == "secondary" ]; then
		prefix="rs.secondaryOk();"
	elif [ "$1" == "master" ]; then
		prefix=' '
	else
		echo "$errCall" 1>&2; return;
	fi
	declare connect=${node[*]}
	echo ''$prefix' '${mongoCmd[*]}'' | $connect | grep -Ev 'CONTROL|NETWORK'
}

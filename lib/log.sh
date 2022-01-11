#!/bin/bash

export stateFile=/var/log/rocketchat/scripts.log

stateLog() {

	if [ $debug -eq 1 ]; then debug "$FUNCNAME $@" ; fi
	statefile=${stateFile}
	base=$(basename $0)
	sed -i '/'$base'/d' $statefile
	echo "$(date +%T\ %d-%m-%Y) $0 $@" >>$statefile
}

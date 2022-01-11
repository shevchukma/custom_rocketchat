#!/bin/bash

errLock="Process lock, lockfile: "

exit_with_rmlock(){

	if [ $debug -eq 1 ]; then debug "$FUNCNAME $@" ; fi
	rm -f "$lockfile";
	kill -s TERM "$TOP_PID";
}

exit_with_rmlock_success(){

	if [ $debug -eq 1 ]; then debug "$FUNCNAME $@" ; fi
	rm -f "$lockfile";
}


exit_without_rmlock(){

	if [ $debug -eq 1 ]; then debug "$FUNCNAME $@" ; fi
	kill -s TERM $TOP_PID;
}

# trap_protector [lockfile]
trap_protector() {

	declare lockfile="$1"
	export TOP_PID=$$

	trap "rm -f $lockfile; echo; exit 1" SIGINT SIGHUP ERR SIGTERM
	# trap "rm -f $lockfile; exit 0" EXIT SIGQUIT

	if [ $debug -eq 1 ]; then debug "$FUNCNAME $@" ; fi
	if [ -f $lockfile ]; then
		echo "$errLock $lockfile";
		exit_without_rmlock
	fi
	echo $$ >$lockfile
}

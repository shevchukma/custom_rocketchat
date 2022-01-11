#!/bin/bash
# shellcheck disable=SC1090,1091,2120,2005,2026,1079,2128

include() {
	if [ -f "$1" ]; then source "$1"; else echo "${NO_FILE} $1" ; exit 0; fi
}

rootpath() { cd -- "$( dirname -- "$(readlink -f "$0")")" &> /dev/null && git rev-parse --show-toplevel; }
declare rootPath="$(rootpath)";
declare scriptPath="${rootPath}/system/monitorInstances";
if [ -f "${rootPath}/.env" ]; then source "${rootPath}/.env"; fi
if [ -f "${scriptPath}/.env" ]; then source "${scriptPath}/.env"; fi

# get lib
include "${rootPath}/lib/debug.sh";
include "${rootPath}/lib/trap.sh";
include "${rootPath}/lib/rest.sh";
include "${scriptPath}/instances.sh"
source "${rootPath}/connections/restAuth/restAuth.sh" "$server"

trap_protector $lockfile

parameter="Troubleshoot_Disable_Presence_Broadcast"
if [ "$(getSettings $parameter)" == "true" ]; then
	exit_with_rmlock;
fi

parameters=(-w "%{time_total}" -m "${requestTime}" -o /dev/null)

bad=0;
flag=0;

for i in "${instances[@]}"; do
	declare instance="$i"
	if ! rc="$(statusInstance)"; then
		if [ $flag -eq 0 ]; then
			date +%d-%m-%Y\ %T\ %Z: | tee -a $logFile
			flag=1;
		fi
		echo "${instance}: error" | tee -a $logFile
		bad=$(($bad + 1))
		continue
	fi
	returnTime=$(awk -F. '{print $1}' <<< "$rc")
	if [ "$returnTime" -gt "$answerTime" ] ; then
		if [ $flag -eq 0 ]; then
			date +%d-%m-%Y\ %T\ %Z: | tee -a $logFile
			flag=1;
		fi
 		echo "${instance}: answerTime = $rc" | tee -a $logFile
		bad=$(($bad + 1))
 	fi
done;

if [ "$bad" -gt ${badContainers} ]; then
	echo presence off | tee -a $logFile
fi
if [ $flag -eq 1 ]; then
	echo "" | tee -a $logFile
fi

exit_with_rmlock

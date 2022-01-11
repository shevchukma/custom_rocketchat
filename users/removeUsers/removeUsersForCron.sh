#!/bin/bash
# shellcheck disable=SC1090,1091,2120,2005,2026,1079,2128
# Delete disabled users, over 180 days

include() {
	if [ -f "$1" ]; then source "$1"; else echo "${NO_FILE} $1" ; exit 0; fi
}

rootpath() { cd -- "$( dirname -- "$(readlink -f "$0")")" &> /dev/null && git rev-parse --show-toplevel; }
declare rootPath="$(rootpath)";
declare scriptPath="${rootPath}/users/removeUsers";
if [ -f "${rootPath}/.env" ]; then source "${rootPath}/.env"; fi
if [ -f "${scriptPath}/.env" ]; then source "${scriptPath}/.env"; fi

# get lib
include "${rootPath}/lib/trap.sh";
include "${rootPath}/lib/log.sh";

trap_protector $lockfile
bash "${scriptPath}/${scriptName}.sh" &>> $logFile
stateLog
exit_with_rmlock

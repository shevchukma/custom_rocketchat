#!/bin/bash
# shellcheck disable=SC1090,1091,2120,2005,2026,1079,2128

include() {
	if [ -f "$1" ]; then source "$1"; else echo "${NO_FILE} $1" ; exit 0; fi
}

rootpath() { cd -- "$( dirname -- "$(readlink -f "$0")")" &> /dev/null && git rev-parse --show-toplevel; }
declare rootPath="$(rootpath)";
declare scriptPath="${rootPath}/system/presenceBroadcast";
if [ -f "${rootPath}/.env" ]; then source "${rootPath}/.env"; fi
if [ -f "${scriptPath}/.env" ]; then source "${scriptPath}/.env"; fi

# get lib
include "${rootPath}/lib/debug.sh";
include "${rootPath}/lib/trap.sh";
include "${rootPath}/lib/rest.sh";
source "${rootPath}/connections/restAuth/restAuth.sh" "$server"

trap_protector $lockfile

action=$1
if [ $action == "on" ] || [ $action == "true" ]; then
	action=false;
else
	action=true;
fi

parameter="Troubleshoot_Disable_Presence_Broadcast"
setSettings $parameter $action

exit_with_rmlock

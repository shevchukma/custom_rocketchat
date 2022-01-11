#/bin/bash
# shellcheck disable=SC1090,2120,2005,2026,1079,212

rootpath() { cd -- "$( dirname -- "$(readlink -f "$0")")" &> /dev/null && git rev-parse --show-toplevel; }
declare rootPath="$(rootpath)";
declare scriptPath="${rootPath}/system/customLDAP/customPhoto";
if [ -f "${rootPath}/.env" ]; then source "${rootPath}/.env"; fi
if [ -f "${scriptPath}/.env" ]; then source "${scriptPath}/.env"; fi

include "${rootPath}/lib/debug.sh"
include "${rootPath}/lib/trap.sh"
include "${rootPath}/lib/rest.sh"
source "${rootPath}/connections/restAuth/restAuth.sh" "$server"

if echo "$@" | grep -q -o '\-h' >>/dev/null; then errCall; exit; fi
if [ $# -ne 2 ]; then errCall; exit 1; fi

trap_protector $lockfile

date >>$logFile
echo $0 "$@" >>$logFile

targetUser=$1
targetPhoto=$2

#custom photo, use: -f ~/photo.jpg
get_photo
setSettings "Accounts_AllowUserAvatarChange" true &>>/dev/null
set_photo | tee -a $logFile
setSettings "Accounts_AllowUserAvatarChange" false &>>/dev/null

exit_with_rmlock_success

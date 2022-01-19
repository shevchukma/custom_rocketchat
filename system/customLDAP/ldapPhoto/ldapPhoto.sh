#/bin/bash
# shellcheck disable=SC1090,2120,2005,2026,1079,212

rootpath() { cd -- "$( dirname -- "$(readlink -f "$0")")" &> /dev/null && git rev-parse --show-toplevel; }
declare rootPath="$(rootpath)";
declare scriptPath="${rootPath}/system/customLDAP/ldapPhoto";
if [ -f "${rootPath}/.env" ]; then source "${rootPath}/.env"; fi
if [ -f "${scriptPath}/.env" ]; then source "${scriptPath}/.env"; fi

include "${scriptPath}/local.sh"
include "${rootPath}/lib/debug.sh"
include "${rootPath}/lib/trap.sh"
include "${rootPath}/lib/rest.sh"
source "${rootPath}/connections/restAuth/restAuth.sh" "$server"

trap_protector $lockfile

if [ $# -ne 1 ]; then echo "${ERR_EXEC}"; exit_with_rmlock; fi

getPhoto
setSettings "Accounts_AllowUserAvatarChange" true &>>/dev/null
setPhoto
setSettings "Accounts_AllowUserAvatarChange" false &>>/dev/null

exit_with_rmlock_success

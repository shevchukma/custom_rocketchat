#/bin/bash
# shellcheck disable=SC1090,2120,2005,2026,1079,212

rootpath() { cd -- "$( dirname -- "$(readlink -f "$0")")" &> /dev/null && git rev-parse --show-toplevel; }
declare rootPath="$(rootpath)";
declare scriptPath="${rootPath}/system/customLDAP/customData";
if [ -f "${rootPath}/.env" ]; then source "${rootPath}/.env"; fi
if [ -f "${scriptPath}/.env" ]; then source "${scriptPath}/.env"; fi

include "${rootPath}/lib/debug.sh"
include "${rootPath}/lib/trap.sh"
include "${rootPath}/lib/rest.sh"
source "${rootPath}/connections/restAuth/restAuth.sh" "$server"

trap_protector $lockfile

#get data from ldap | merge >"$JSON"

if [ -z "$userId" ]; then
    echo "$errUserNotFound $userName"; exit 1;
fi

setSettings "Accounts_AllowRealNameChange" true &>>/dev/null
setData
setSettings "Accounts_AllowRealNameChange" false  &>>/dev/null

exit_with_rmlock

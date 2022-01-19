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

date >>$logFile
echo $0 "$@" >>$logFile

if [ $# -eq 0 ]; then errCall; localHelp; exit 1; fi
if echo "$@" | grep -q -o '\-h'; then localHelp; exit; fi

{
    while getopts "u:n:m:p:c:t:d:l:r:" opt; do
        case "$opt" in
            u) userName="$OPTARG"; userId=$(get_id $userName) ;;
            n) echo '{"userId": "'"$userId"'","data": {"name": "'"$OPTARG"'"}}' ;;
            m) echo '{"userId": "'"$userId"'","data": {"customFields": {"Mail": "'"$OPTARG"'"}}}' ;;
            p) echo '{"userId": "'"$userId"'","data": {"customFields": {"Tel": "'"$OPTARG"'"}}}' ;;
            c) echo '{"userId": "'"$userId"'","data": {"customFields": {"City": "'"$OPTARG"'"}}}' ;;
            t) echo '{"userId": "'"$userId"'","data": {"customFields": {"Title": "'"$OPTARG"'"}}}' ;;
            d) echo '{"userId": "'"$userId"'","data": {"customFields": {"Department": "'"$OPTARG"'"}}}' ;;
            l) echo '{"userId": "'"$userId"'","data": {"customFields": {"Link": "'"$OPTARG"'"}}}' ;;
            r) echo '{"userId": "'"$userId"'","data": {"roles": ["'"$OPTARG"'"]}}' ;;
            *) echo '{"userId": "'"$userId"'"}';;
        esac
    done
} | merge >"$json"

if [ -z "$userId" ]; then
    echo "$errUserNotFound $userName"; exit 1;
fi

setSettings "Accounts_AllowRealNameChange" true &>>/dev/null
setData | tee -a $logFile
setSettings "Accounts_AllowRealNameChange" false  &>>/dev/null

exit_with_rmlock_success

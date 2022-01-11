#!/bin/bash
# shellcheck disable=SC1090,2120,2005,2026,1079,2128,2154
# script write credentinal userId and authToken in file

# get env
rootpath() { cd -- "$( dirname -- "$(readlink -f "$0")")" &> /dev/null && git rev-parse --show-toplevel; }
declare rootPath="$(rootpath)";
declare scriptPath="${rootPath}/connections/restAuth"
if [ -f "${rootPath}/.env" ]; then source "${rootPath}/.env"; fi
if [ -f "${scriptPath}/.env" ]; then source "${scriptPath}/.env"; fi

# get lib
include "${rootPath}/lib/debug.sh";

if [ $debug -eq 1 ]; then debug $scriptName $@; fi
if [ $# -ne 1 ]; then echo "$errCall"; exit 1; fi
if ! curl -k -s -o /dev/null -m 3 "https://$SERVER//api/info"; then echo "$errApi"; exit 1; fi
if [ -f "$authFile" ]; then include "$authFile"; else touch "$authFile"; fi

# check correct login/token;
while [ "$(check_credentinal)" == "error" ]; do

    if [[ "$numAuth" == 3 ]]; then echo "$errTry"; exit 0; fi;

    # first try login
    if [[ "$flag" == 0 ]]; then
        if [ "$USER" == "rocketchat_service" ]; then echo "$rcSrvErrAuth"; exit 1; fi
        echo "$errAuth"; flag=1;
    fi

    # message for second and more logins
    if [[ "$flag" == 1 ]]; then echo "$askCred"; flag=2; else echo -e "${errConn}\n"; fi

    read -p "login: " -r login; read -p "password: " -rs password; echo "";

    curl -k -s -X POST "https://$SERVER/api/login" \
        -H "Content-Type: application/json" \
        -d '{"ldapPass": "'"$password"'" , "ldapOptions": [], "ldap": true, "username": "'"$login"'" }' \
        | jq '.data | "userId=\(.userId); authToken=\(.authToken)"' \
        | sed 's/"//g' > "${authFile}"
    numAuth=$(("$numAuth" + 1));
    include "$authFile"
done;
if [ "$USER" != "rocketchat_service" ]; then if [ "$scriptName"  == "$rootScriptName" ]; then echo "$keyValid"; fi; fi

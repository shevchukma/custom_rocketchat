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
include "${rootPath}/lib/debug.sh";
include "${rootPath}/lib/trap.sh";
source "${rootPath}/connections/restAuth/restAuth.sh" "$server"

if [ "$scriptName"  == "$rootScriptName" ]; then
	trap_protector lockFile;
fi

date

# Проверка установленных пакетов
jq --version &>>/dev/null || yum install jq -y &>>/dev/null || apt install jq -y &>>/dev/null


# Проверочная дата, текущая дата минус long дней
checkDate=$(date --date "-$long days" +%Y-%m-%dT%H:%M:00.000Z);

# echo "name: active: lastLogin:"
for i in $(seq 0 60 9000)
do
    line=$(curl -s -G -H "X-Auth-Token: $authToken" -H "X-User-Id: $userId" -H "Accepts: application/json" \
    --data-urlencode 'fields={ "username":1, "active":1, "lastLogin":1 }' \
    --data-urlencode 'query={"active": false,"lastLogin":{"$lt":{"$date": "'$checkDate'" }}}' \
    --data-urlencode "offset=$i" \
    https://$server/api/v1/users.list)

    # Выход из цикла offset'ов(от 0 до 9000), когда количество результатов 0
    if [ "$(echo $line | jq .count)" == 0 ]; then
        break;
    else
        remove_list+=("$(printf "%s" "$line"| jq '.users[].username'|sed 's/"//g')")
        remove_list=($(for i in ${remove_list[@]}; do echo $i; done | sort -u))
    fi;
done

# check empty list for remove
if [[ "${#remove_list[*]}" == 0 ]]; then
    echo -e "$outputNoElements\n" >&2; exit_with_rmlock
fi

num=0;
del=0
printf "%4s %-20s %s\n" " " "NAME:" "RESULT:"
for i in ${remove_list[@]}; do
	num=$(($num + 1))
    result=$(curl -s -H "X-Auth-Token: $authToken" -H "X-User-Id: $userId" -H "Content-type:application/json" https://$server/api/v1/users.delete -d '{ "username": "'"$i"'", "confirmRelinquish": true }')
	if [[ $result =~ "true" ]]; then del=$(($del + 1)); fi
    printf "%4d.%-20s %s\n" $num "$i:" $result
done;
echo -e "Total: $num, Remove: $del\n\n"
if [ -f $tempFile ]; then rm $tempFile; fi

if [ "$scriptName"  == "$rootScriptName" ]; then
    exit_with_rmlock
fi

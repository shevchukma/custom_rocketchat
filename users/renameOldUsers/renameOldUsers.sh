#!/bin/bash
# shellcheck disable=SC1090,1091,2120,2005,2026,1079,2128

include() {
	if [ -f "$1" ]; then source "$1"; else echo "${NO_FILE} $1" ; exit 0; fi
}

rootpath() { cd -- "$( dirname -- "$(readlink -f "$0")")" &> /dev/null && git rev-parse --show-toplevel; }
declare rootPath="$(rootpath)";
declare scriptPath="${rootPath}/users/renameOldUsers";
if [ -f "${rootPath}/.env" ]; then source "${rootPath}/.env"; fi
if [ -f "${scriptPath}/.env" ]; then source "${scriptPath}/.env"; fi

# get lib
include "${rootPath}/lib/debug.sh";
include "${rootPath}/lib/trap.sh";
include "${rootPath}/lib/mongo.sh";
include "${rootPath}/lib/date.sh";
include "${rootPath}/lib/rest.sh";
include "${rootPath}/connections/mongoConnect/mongoConnect.sh";
source "${rootPath}/connections/restAuth/restAuth.sh" "$server"

trap_protector $lockfile
replaceUser=$(getName "$1")

date >>$logFile
echo $0 "$@" >>$logFile

# rest
userStats=($(getUserStats))
userStatsId=${userStats[0]}
userStatsEmail=${userStats[1]}
userStatsActive=${userStats[2]}
if [ -z "$userStatsId" ]; then
        if [ $USER == "rocketchat_service" ]; then
                echo -e $errWrongNameForService | tee -a $logFile;
        else
                echo -e $errWrongName | tee -a $logFile;
        fi
        exit_with_rmlock;
elif [ "$userStatsActive" == "true" ]; then
        if [ $USER == "rocketchat_service" ]; then
                echo -e $errUserActiveForService  | tee -a $logFile;
        else
                echo -e $errUserActive | tee -a $logFile;
        fi
        exit_with_rmlock;
fi
result=true
num=0; while $result; do
        num=$(($num + 1));
        result=$(searchEmptyName | jq .success);
done

toName=$(echo "$replaceUser"_old$(printf "%02d" "$num"))
toEmail=$(echo "$userStatsEmail" | sed 's/\@/_old'$(printf "%02d" "$num")'\@/')

renameUser
resutlRenameUser=$(get_id ${toName})
# mongodb
if [ "$resutlRenameUser" != "null" ]; then
        command='db.users.update( { "username" : /'$toName'/i},{ $unset: {"services.ldap":"", "services.keycloak":""}})'
        if mongoCommand master command &>> $logFile; then
                if [ $USER == "rocketchat_service" ]; then echo -e ${successUpdateForService}; else echo "true"; fi
        else
                if [ $USER == "rocketchat_service" ]; then echo -e ${errUpdateForService}; else echo "[err]: not set mongodb"; fi
        fi
        echo "" >> $logFile
else
        if [ $USER == "rocketchat_service" ]; then echo -e ${errUpdateForService}; else echo "[err]: not rename"; fi
fi

exit_with_rmlock

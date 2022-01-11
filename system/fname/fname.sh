#!/bin/bash

rootpath() { cd -- "$( dirname -- "$(readlink -f "$0")")" &> /dev/null && git rev-parse --show-toplevel; }
rootPath="$(rootpath)";
scriptPath="${rootPath}/system/fname";
if [ -f "${rootPath}/.env" ]; then source "${rootPath}/.env"; fi
if [ -f "${scriptPath}/.env" ]; then source "${scriptPath}/.env"; fi

# get lib
include "${rootPath}/lib/debug.sh";
include "${rootPath}/lib/trap.sh";
include "${rootPath}/lib/date.sh";
include "${rootPath}/connections/mongoConnect/mongoConnect.sh";
include "${rootPath}/lib/mongo.sh";
include "${scriptPath}/libfname.sh";



offset=50					# [0 to 50], offset to step for update on primary node, max set 50, value "max_step" in libfname.sh
interval=0					# [0 to 30] interval to step for update on primary node,max set 30, value "max_step_interval" in libfname.sh

trap_protector $lockfile

touch $logFile $logFile.tmp
date >>$logFile
echo "${scriptName}: $@" >>$logFile

if [ -z $1 ]; then
	declare command=${commandFullFname}
else
	declare dates=($(allDates $@))
	declare rangeDates=($(date_get_mongo_ignore ${dates[@]}))
	declare command='db.rocketchat_subscription.find({ t: "d","_updatedAt" : {$gte: ISODate("'${rangeDates[0]}'"), $lt: ISODate("'${rangeDates[1]}'")}}).forEach(function (subscription) { var user = db.users.findOne({ username: subscription.name }); if (!user || !user.name ) {return}; if (subscription.fname != user.name) { print("{\"_id\":\"" + subscription._id + "\",\"fname\":\"" + user.name + "\"}") }; })'
fi

declare arr=($(mongoCommand secondary command  | tee $tempFile))
declare numElements=$(echo ${arr[@]} | awk -F '[{}]' '{printf "%d", NF }')
declare elements=$(($numElements / 2))

# UPDATE DATA
if [ "$numElements" -eq 0 ]; then
	echo "$errNoItems" | tee -a $logFile 1>&2
else
	command='db.rocketchat_subscription.update({ _id: list[i]._id }, {$set: { fname: list[i].fname }})'
	step_operation arr "$offset" command master "$interval" >>"$logFile"
fi

echo -e "count: ${elements}\n" >>"$logFile"

# ## ## ## ## use for set db.user.name for all users, if db.rochechat_subscription is actual
# if [ $numElements -eq 0 ]; then
# 	set_all_db_users_name "hohloma"
# fi

exit_with_rmlock

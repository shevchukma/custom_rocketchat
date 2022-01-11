#/bin/bash

rootpath() { cd -- "$( dirname -- "$(readlink -f "$0")")" &> /dev/null && git rev-parse --show-toplevel; }
declare rootPath="$(rootpath)";
declare scriptPath="${rootPath}/users/scanActive";
if [ -f "${rootPath}/.env" ]; then source "${rootPath}/.env"; fi
if [ -f "${scriptPath}/.env" ]; then source "${scriptPath}/.env"; fi

include "${rootPath}/lib/debug.sh"
include "${rootPath}/lib/trap.sh"
include "${rootPath}/lib/mongo.sh"
include "${rootPath}/lib/date.sh"
include "${rootPath}/connections/mongoConnect/mongoConnect.sh";

if ! echo $@ | grep -q -E '\-u|\-g|\-s' ; then localHelp; exit 1; fi
trap_protector $lockfile

#echo "$(date +%d.%m.%Y\ %T): $(basename $0): $@" >>$LOG
while getopts "u:" opt; do
    case "$opt" in
        u) user="$OPTARG";;
    esac
done

echo -e "\n[g]  - group\n[p]  - private\n[jc] - jitsi call\n[uj] - user join\n[ru] - remove user\n[rm] - remove message\n[rc] - room change\n[sa] - subscription-role-added\n"
declare dates=($(allDates $@)); if [ ${#dates[@]} -eq 0 ]; then	dates=$(allDates $(date --date "-1 day" +%d.%m.%Y)); fi
declare mongoDates=($(date_get_mongo ${dates[@]}))

SEARCH='{"u.username":"'$user'", "ts" : {$gte: ISODate("'${mongoDates[0]}'"),$lt: ISODate("'${mongoDates[1]}'")}}'
command='db.rocketchat_message.find('$SEARCH').
forEach(function (message) {
	var name = db.rocketchat_room.findOne({ _id : message.rid });
	if (!name.name) {
		if (!message.t) {
			print("[p] " + name.usernames)}
		else
			print("[" + message.t + "] " + name.usernames)
	}
	else {
		var name = db.rocketchat_room.findOne({ _id : message.rid });
		if (!message.t) {
			print("[g] " + name.name)
		}
		else {
			print("[" + message.t + "] " + name.name)
		}
	}
})'
mongoCommand secondary command |
sed -E '/CONTROL/! {/NETWORK/! { s/ISODate\(//g;s/Z"\)/"/g;s/\.([0-9]{3})//g;}}' |
sed 's/jitsi_call_started/jc/;s/\[room.*\]/[rc]/;s/\[subscription-role-added.*\]/[sa]/;' |
sort |	uniq -c | sort -k 1 -n -r |
awk 'BEGIN{print "'$user':"};{printf "%-4d %5s: %s\n", $1, $2, $3}END{print " "}'

exit_with_rmlock

#/bin/bash

rootpath() { cd -- "$( dirname -- "$(readlink -f "$0")")" &> /dev/null && git rev-parse --show-toplevel; }
declare rootPath="$(rootpath)";
declare scriptPath="${rootPath}/messages/getHistory";
if [ -f "${rootPath}/.env" ]; then source "${rootPath}/.env"; fi
if [ -f "${scriptPath}/.env" ]; then source "${scriptPath}/.env"; fi

include "${rootPath}/lib/debug.sh"
include "${rootPath}/lib/trap.sh"
include "${rootPath}/lib/mongo.sh"
include "${rootPath}/lib/date.sh"
include "${rootPath}/connections/mongoConnect/mongoConnect.sh";

trap_protector $lockfile

if ! echo $@ | grep -q -E '\-u|\-g|\-s' ; then localHelp; exit 1; fi
declare dates=($(allDates $@))

while getopts "u:g:s:" opt; do
    case "$opt" in
        u) userSearch="$OPTARG";;
        g) groupSearch="$OPTARG";;
        s) stringSearch="$OPTARG";;
    esac
done

declare mongoDates=($(date_get_mongo_ignore ${dates[@]}))
if ! [ -z $userSearch ]; then mgroupSearch='"u.username":"'$userSearch'",'; fi
if ! [ -z $groupSearch ]; then
	if [[ $groupSearch =~ , ]]; then
		usernames=$(echo $groupSearch | sed -e 's/^/[ "/;s/,/", "/;s/$/" ]/' )
		command='db.rocketchat_room.find({"usernames":'$usernames'}).forEach(function (room){print(room._id)})';
	else
		command='db.rocketchat_room.find({"name":"'$groupSearch'"}).forEach(function (room){print(room._id)})';
	fi
	mg_rid=$(mongoCommand secondary command); mg_rid='"rid":"'$mg_rid'",';
fi
if ! [ -z "$stringSearch" ]; then mg_str='$or:[{"msg":{$regex: "'$stringSearch'"}}, {"attachments.description":{$regex: "'$stringSearch'"}}],'; fi
if [ ${#mongoDates[@]} -eq 2 ]; then mg_ts='"ts" : {$gte: ISODate("'${mongoDates[0]}'"),$lt: ISODate("'${mongoDates[1]}'")}'; fi

SEARCH='{'$mgroupSearch''$mg_rid''$mg_str''$mg_ts'}';
if [ "$SEARCH" == "{}" ]; then echo "EMPTY PARAMETERS"; exit_with_rmlock; fi
command='db.rocketchat_message.find('$SEARCH').sort({ts:1}).forEach(function (message) {
var room = db.rocketchat_room.findOne({_id : message.rid});
if (room.usernames)
	if (message.t)
		print('$priv_sys');
	else
		if (message.file)
			if (message.attachments[0].description)
				if (message.attachments[0].image_url)
					print('$priv_att_desc_image_url');
				else if (message.attachments[0].title_link)
					print('$priv_att_desc_title_link');
				else
					print('$priv_att_only_desc');
			else if (message.attachments[0].image_url)
				print('$prive_att_image_url');
			else if (message.attachments[0].title_link)
				print('$priv_att_title_link');
			else
				print('$priv_att_exception');
		else
			print('$priv_msg');
else
	if (message.t)
		print('$group_sys');
	else
		if (message.file)
			if (message.attachments[0].description)
				if (message.attachments[0].image_url)
					print('$group_att_desc_image_url');
				else if (message.attachments[0].title_link)
					print('$group_att_desc_title_link');
				else
					print('$group_att_desc');
			else if (message.attachments[0].image_url)
				print('$group_att_image_url');
			else if (message.attachments[0].title_link)
				print('$group_att_title_link');
			else
				print('$group_att_extention');
		else
			print('$group_msg');
})'

echo 'date: time: room: user: attach: msg: ' >"$TMP"
mongoCommand secondary command |
sed '/<<END>>/! {:l;N;/}\n/{s/\n/A/g;b}; s/\n//g;bl;}' |
sed -e 's/<<END>>/\n/g' |
sed -e '/^$/d' -e 's/^....//' -e 's/Jan/01/' -e 's/Feb/02/' -e 's/Mar/03/' -e 's/Apr/04/' -e 's/May/05/' -e 's/Jun/06/' -e 's/Jul/07/' -e 's/Aug/08/' -e 's/Sep/09/' -e 's/Oct/10/' -e 's/Nov/11/' -e 's/Dec/12/' -e 's/GMT+0300 (MSK) //' |
sed -E 's/(.{2})\ (.{2})\ (.{4}) /\2-\1-\3 /' >>"$TMP"

if [ $(cat "$TMP" | wc -l) -ge 2 ]; then
	if [ -f $ft_column ]; then
		$ft_column "$TMP" -t 5
	else
		cat "$TMP"
	fi
fi

rm "$TMP"
exit_with_rmlock

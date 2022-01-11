#!/bin/bash

p_name="update_group.sh"
DIR=$(dirname $(readlink -f $(which $0)))

source $DIR/../../lib/parameters.sh
source $DIR/../../lib/trap.sh
source $DIR/../../lib/debug.sh
source $DIR/../../lib/lib.sh
source $DIR/../../lib/rest.sh

if [ -z $script ]; then
	LOCKFILE=/tmp/$p_name.lock
	trap_protector $LOCKFILE 1>&2
	SERVER=rcdev.home.org
	AUTH_FILE=~/rocket_auth
	DEBUG=0
fi

get_action(){
	if [ $(get_parameter d $@) == "d" ]; then
		echo "kick";
	else
		echo "invite"
	fi
}

get_api(){
	action=$(get_action $@)
	info_api="https://$SERVER/api/v1/groups.info?roomName=$room_name"
	if [ "$(curl -s -H "X-Auth-Token: $userToken" -H "X-User-Id: $userId" "$info_api"|jq .success)" == "true" ]; then
		echo "/api/v1/groups.$action"
	else
		echo "/api/v1/channels.$action"
	fi;
}

set_group(){
	curl -s -H "X-Auth-Token: $userToken" \
    	-H "X-User-Id: $userId" \
        -H "Content-type: application/json" \
        -d '{ "roomName": "'$room_name'", "username": "'$user_name'" }' \
		"https://$SERVER/$API" #| jq .success
}

# update_group [user] [group] [-d for kick]
update_group(){

	if [ -z $script ]; then
		source $DIR/../rest_auth/rest_auth.sh $SERVER
		userId=$(cut -b 1-17 "${AUTH_FILE}" 2>>/dev/null)
		userToken=$(cut -b 19-62 "${AUTH_FILE}" 2>>/dev/null)
	fi

	user_name=$(get_user $@)
	room_name=$(get_group $@)
	export API=$(get_api $@)
	set_group
}


if [ -z $script ]; then
	update_group $@
	rm $LOCKFILE
fi



get_data_groups(){
    lib_info_level $FUNCNAME $@
	local u_name=$1

	# AD answer to request, default port 636
	#ldapsearch -x -b "OU=[OU],DC=[DC],DC=[DC]" -H ldap://[ip_srv] -D "[user_ldap]]@[domain]]" -W "(&(objectCategory=Person)(sAMAccountName=[need_user]))"
    ldap="/bin/cat /home/dbudakov/Downloads/$u_name.txt"

	$ldap | sed -z 's/\n //g' | grep ":" >$tmp_file
    if ! grep sAMAccountName $tmp_file >>/dev/null ; then
        echo err_ldap;
        return 1;
    fi
	mail=$(cat $tmp_file | awk '/mail/ && /@/ {print $2}')
    if check_mail $mail $u_name; then
        cat $tmp_file | awk -F '[,=]' '/memberOf/ {print $2}'
    fi
}


update_group_ldap(){
	local u_name=$1
	groups=($(get_data_groups $u_name))
	flag_out="false"
	for gr in $(echo ${groups[@]}); do
		if [ "$gr" == "group1" ]; then update_group $u_name room1;flag_out="true"; continue; fi
		if [ "$gr" == "group2" ]; then update_group $u_name room2;flag_out="true"; continue; fi
	done
	if [ $flag_out == "false" ]; then echo "skeep"; fi
}

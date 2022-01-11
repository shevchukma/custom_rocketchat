#!/bin/bash
# shellcheck disable=SC1090

NO_FILE="$0: No such file"

include() {
	if [ -f "$1" ]; then source "$1"; echo 1; else echo "${NO_FILE} $1" ; exit 0; fi
}

DIR=$(dirname "$(readlink -f "$(which "$0")")")
include "$DIR/../../lib/lib.sh"
include "$DIR/../../lib/trap.sh"
include "$DIR/../../lib/rest.sh"
include "$DIR/../../lib/parameters.sh"
include "$DIR/permission.sh"

# get_data [username] [to_file]

data=~/update_data.tmp
tmp_file=~/data.tmp
export mail_pattern=$DIR/mail_pattern
template=~/update_data.template
u_name=$1
DEBUG=0

if [ -z "$script" ]; then
	LOCKFILE=/tmp/update_data.lock
	trap_protector $LOCKFILE 1>&2
	SERVER=rcdev.home.ru
	AUTH_FILE=~/rocket_auth
fi

check_mail(){

    lib_info_level "$FUNCNAME" "$@"
    local i;
    if ! (echo "$@" | grep @ >/dev/null) ; then return 0; fi
    for i in $(echo $(cat $mail_pattern)); do
        if [[ "$1" =~ "$i"$ ]]; then
            return 0;
        fi
    done;
    echo "$1" | awk -F@ '{print "@"$2}'
    return 1;
}

get_data(){

    lib_info_level $FUNCNAME "$@"
	local u_name=$1
	local data=$2

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
        if [ "$(cat $tmp_file | awk '/displayName:/ {print NF}')" -eq 2 ]; then
            displayName=$(cat $tmp_file | awk '/displayName:/ {print $2}' | base64 -d | sed 's/"/\\"/g')
        else
            displayName=$(cat $tmp_file | awk '/displayName:/ {for (i=2; i<=NF; i++) print $i}')
        fi
        if [ $(cat $tmp_file | awk '/telephoneNumber:/ {print $2}'|wc -c) -lt 12 ]; then
            telephoneNumber=$(cat $tmp_file | awk '/telephoneNumber:/ {print $2}')
        fi
        city=$(cat $tmp_file | awk '/l::/ {print $2}'|base64 -d | sed 's/"/\\"/g')
        title=$(cat $tmp_file | awk '/title:/ {print $2}'|base64 -d | sed 's/"/\\"/g')
        department=$(cat $tmp_file | awk '/department:/ {print $2}'| base64 -d | sed 's/"/\\"/g')
        link=$(cat $tmp_file | awk '/LegalStructure/ {print $2}' | base64 -d | sed 's/"/\\"/g')
       	local u_id=$(get_id $u_name)
        echo '{"userId": "'$u_id'",
        "data": {
            "name": "'$displayName'",
            "customFields": {
                "Mail": "'$mail'",
                "Tel": "'$telephoneNumber'",
                "City": "'$city'",
                "Title": "'$title'",
                "Department": "'$department'",
                "Link": "'$link'"
        }}}' >$data
    else
        >$data
        return 1;
    fi
}


# set_data [data_file], u_id in file
set_data(){

    lib_info_level $FUNCNAME "$@"
    local data=$1

    API="api/v1/users.update"
    if cat $data | jq . &>>/dev/null && ! check_empty_file $data ; then
        curl -s -H "X-User-Id: $userId" \
            -H "X-Auth-Token: $userToken" \
            -H "Content-type: application/json" \
            "https://$SERVER/$API" \
            --data "@$data" | jq .success
    else
        echo -n "not_valid_file"
        if [ -z $script ]; then echo; fi
    fi
}

template_json(){
    lib_info_level $FUNCNAME $@
    echo -e '{\n\t"userId": "'_id'",\n\t"data": {\n\t\t"name": "'displayName'",\n\t\t"customFields": {
                    "Mail": "'mail'",\n\t\t"Tel": "'telephoneNum'",\n\t\t"City": "'city'",\n\t\t"Title": "'title'",
                    "Department": "'department'",\n\t\t"Link": "'link'"}\n\t}\n}'
}

update_data(){

    lib_info_level $FUNCNAME "$@"
    if [ $1 == "-e" ] ; then
        template_json >$template
        echo $template
        rm $LOCKFILE
        exit 0;
    elif [ $1 == "-f" ] ; then
        custom_data="$2";
    else
        local u_name=$1
    fi

    if [ -z $script ]; then
    	source $DIR/../rest_auth/rest_auth.sh $SERVER
    	export userId=$(cut -b 1-17 "${AUTH_FILE}" 2>>/dev/null)
    	export userToken=$(cut -b 19-62 "${AUTH_FILE}" 2>>/dev/null)
    fi

    if [ -z $custom_data ]; then
    	if ! get_data $u_name $data; then
            return 1;
        fi
    else
        data=$custom_data
    fi

    if [ -z $script ]; then
        parameter="Accounts_AllowRealNameChange"
        set_permission $parameter true
    fi

    set_data $data

    if [ -z $script ]; then
        parameter="Accounts_AllowRealNameChange"
        set_permission $parameter false
    fi
}

if [ -z $script ]; then
    update_data "$@"
    rm $LOCKFILE
fi

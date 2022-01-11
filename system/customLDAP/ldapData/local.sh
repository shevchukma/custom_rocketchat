#!/bin/bash
# shellcheck disable=SC2086,2154,2120,1091


server=rcdev.home.ru
LOCKFILE=/tmp/update_data.lock
AUTH_FILE=~/rocket_auth

data=~/update_data.tmp
template=~/update_data.template
u_name=$1

template_json(){

    lib_info_level $FUNCNAME "$@"
    echo -e '{\n\t"userId": "'_id'",\n\t"data": {\n\t\t"name": "'displayName'",\n\t\t"customFields": {
                    "Mail": "'mail'",\n\t\t"Tel": "'telephoneNum'",\n\t\t"City": "'city'",\n\t\t"Title": "'title'",
                    "Department": "'department'",\n\t\t"Link": "'link'"}\n\t}\n}'
}


check_mail(){

    lib_info_level "$FUNCNAME" "$@"
    local i;
    if ! (echo "$@" | grep @ >/dev/null) ; then return 0; fi
    for i in $(echo "$(cat $mail_pattern)"); do
        if [[ "$1" =~ "$i"$ ]]; then
            return 0;
        fi
    done;
    echo "$1" | awk -F@ '{print "@"$2}'
    return 1;
}

get_data_ldap() {

	lib_info_level $FUNCNAME "$@"
	local u_name=$1
	local data=$2

	# AD answer to request, default port 636
	#ldapsearch -x -b "OU=[OU],DC=[DC],DC=[DC]" -H ldap://[ip_srv] -D "[user_ldap]]@[domain]]" -W "(&(objectCategory=Person)(sAMAccountName=[need_user]))"

	ldap="/bin/cat /home/dbudakov/Downloads/$u_name.txt"

	$ldap | sed -z 's/\n //g' | grep ":" >"$tempFile"
    if ! grep sAMAccountName "$tempFile" >>/dev/null ; then
        echo err_ldap;
        return 1;
    fi
	mail=$(cat "$tempFile" | awk '/mail/ && /@/ {print $2}')
    if check_mail $mail $u_name; then
        if [ "$(cat "$tempFile" | awk '/displayName:/ {print NF}')" -eq 2 ]; then
            displayName=$(cat "$tempFile" | awk '/displayName:/ {print $2}' | base64 -d | sed 's/"/\\"/g')
        else
            displayName=$(cat "$tempFile" | awk '/displayName:/ {for (i=2; i<=NF; i++) print $i}')
        fi
        if [ "$(cat "$tempFile" | awk '/telephoneNumber:/ {print $2}'|wc -c)" -lt 12 ]; then
            telephoneNumber=$(cat "$tempFile" | awk '/telephoneNumber:/ {print $2}')
        fi
        city=$(cat "$tempFile" | awk '/l::/ {print $2}'|base64 -d | sed 's/"/\\"/g')
        title=$(cat "$tempFile" | awk '/title:/ {print $2}'|base64 -d | sed 's/"/\\"/g')
        department=$(cat "$tempFile" | awk '/department:/ {print $2}'| base64 -d | sed 's/"/\\"/g')
        link=$(cat "$tempFile" | awk '/LegalStructure/ {print $2}' | base64 -d | sed 's/"/\\"/g')
       	u_id=$(get_id $u_name)
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
        echo "" >$data
        return 1;
    fi
}


# set_data [data_file], u_id in file
# set_data(){

#     lib_info_level $FUNCNAME "$@"
#     local data=$1

#     api="api/v1/users.update"
#     if cat $data | jq . &>>/dev/null && ! check_empty_file $data ; then
#         curl -s -H "X-User-Id: $userId" \
#             -H "X-Auth-Token: $userToken" \
#             -H "Content-type: application/json" \
#             "https://$server/$api" \
#             --data "@$data" | jq .success
#     else
#         echo -n "not_valid_file"
#         if [ -z $script ]; then echo; fi
#     fi
# }

# update_data() {

#     lib_info_level $FUNCNAME "$@"
#     if [ $1 == "-e" ] ; then
#         template_json >$template
#         echo $template
#         rm $LOCKFILE
#         exit 0;
#     elif [ $1 == "-f" ] ; then
#         custom_data="$2";
#     else
#         local u_name=$1
#     fi

#     if [ -z $script ]; then
#     	source $DIR/../rest_auth/rest_auth.sh $server
#     	export userId=$(cut -b 1-17 "${AUTH_FILE}" 2>>/dev/null)
#     	export userToken=$(cut -b 19-62 "${AUTH_FILE}" 2>>/dev/null)
#     fi

#     if [ -z $custom_data ]; then
#     	if ! get_data_ldap $u_name $data; then
#             return 1;
#         fi
#     else
#         data=$custom_data
#     fi

#     if [ -z $script ]; then
#         parameter="Accounts_AllowRealNameChange"
#         set_permission $parameter true
#     fi

#     set_data $data

#     if [ -z $script ]; then
#         parameter="Accounts_AllowRealNameChange"
#         set_permission $parameter false
#     fi
# }

#!/bin/bash
# shellcheck disable=SC2086,2154,2120,1091

custom_ldapsearch(){

	if [ $debug -eq 1 ]; then debug "$FUNCNAME $@" ; fi
    # AD answer to request, default port 636
	#ldapsearch -x -b "OU=[OU],DC=[DC],DC=[DC]" -H ldap://[ip_srv] -D "[user_ldap]]@[domain]]" -W "(&(objectCategory=Person)(sAMAccountName=[need_user]))"
	/bin/cat /home/dbudakov/Downloads/$targetUserName.txt
}

template_json(){

	if [ $debug -eq 1 ]; then debug "$FUNCNAME $@" ; fi
    echo -e '{\n\t"userId": "'_id'",\n\t"data": {\n\t\t"name": "'displayName'",\n\t\t"customFields": {
                    "Mail": "'mail'",\n\t\t"Tel": "'telephoneNum'",\n\t\t"City": "'city'",\n\t\t"Title": "'title'",
                    "Department": "'department'",\n\t\t"Link": "'link'"}\n\t}\n}'
}

getData() {

	if [ $debug -eq 1 ]; then debug "$FUNCNAME $@" ; fi
    custom_ldapsearch | sed -z 's/\n //g' | grep ":" >"$tempFile"
    if ! grep sAMAccountName "$tempFile" >>/dev/null ; then
        echo err_ldap;
        return 1;
    fi
	mail=$(cat "$tempFile" | awk '/mail/ && /@/ {print $2}')
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
       	u_id=$(get_id $targetUserName)
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
        }}}' >${JSON}
}

setData(){

    if [ $debug -eq 1 ]; then debug "$FUNCNAME $@" ; fi
    API="api/v1/users.update"
    result=$(curl -s -H "X-User-Id: $userId" \
        -H "X-Auth-Token: $authToken" \
        -H "Content-type: application/json" \
        --data "@$JSON" \
        "https://$server/$API")
    if [ ! "$(echo "$result" | jq .success)" == "true" ] ; then
		echo "$result" | jq .error
	else
		echo "$result" | jq .success
	fi
}

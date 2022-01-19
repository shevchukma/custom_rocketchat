#!/bin/bash
# shellcheck disable=SC2086,2154,2120,1091

custom_ldapsearch(){

	if [ $debug -eq 1 ]; then debug "$FUNCNAME $@" ; fi
    # AD answer to request, default port 636
	#ldapsearch -x -b "OU=[OU],DC=[DC],DC=[DC]" -H ldap://[ip_srv] -D "[user_ldap]]@[domain]]" -W "(&(objectCategory=Person)(sAMAccountName=[need_user]))"
	/bin/cat /home/dbudakov/Downloads/$targetUser.txt
}

getPhoto() {

	if [ $debug -eq 1 ]; then debug "$FUNCNAME $@" ; fi
    custom_ldapsearch | sed -z 's/\n //g' | awk '/photo/ {print $2}' | base64 -d >"${JPEG}"
    >${JPEG}
	jhead -norot "${JPEG}" &>>/dev/null || ( echo ${errFormat} "${JPEG}" >&2 && exit_with_rmlock )
}

setPhoto(){

	api="/api/v1/users.setAvatar"

	targetUserName=$(getName $targetUser)
	if [ $debug -eq 1 ]; then debug "$FUNCNAME $@" ; fi
	result=$(curl -s -H "X-User-Id: $userId" \
		-H "X-Auth-Token: $authToken" \
  		-H "Content-type: multipart/form-data" \
  		-F "username=$targetUserName" \
  		-F "image=@${JPEG}" \
		"https://$server/$api")
	if [ ! "$(echo "$result" | jq .success)" == "true" ] ; then
		echo $result | jq .error
	else
		echo $result | jq .success
	fi
}

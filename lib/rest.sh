#!/bin/bash
# shellcheck disable=SC2120,2128,2237,2068,2086


# logout id tocken server
logout()
{
    curl -s -H "X-Auth-Token: $auth_token" -H "X-User-Id: $user_id" -X POST https://$SERVER/api/v1/logout &>>/dev/null
}


get_id() {

    if [ $debug -eq 1 ]; then debug "$FUNCNAME $@" ; fi
    local u_name=$1

    API="/api/v1/users.info"
    result="$(curl -s -H "X-User-Id: $userId" -H "X-Auth-Token: $authToken" -H "Content-type: application/json" "https://$server/$API?username=$u_name" | jq .success  2>>/dev/null)"
    if [ "$result" == "false" ]; then
        u_name=$(echo $1 |awk '{print tolower($0)}')

    fi
    curl -s -H "X-User-Id: $userId" -H "X-Auth-Token: $authToken" -H "Content-type: application/json" "https://$server/$API?username=$u_name" | jq .user._id  2>>/dev/null  | sed 's/^"//;s/"$//'
}

getName() {

    if [ $debug -eq 1 ]; then debug "$FUNCNAME $@" ; fi
    local u_name=$1

    API="/api/v1/users.info"
    result="$(curl -s -H "X-User-Id: $userId" -H "X-Auth-Token: $authToken" -H "Content-type: application/json" "https://$server/$API?username=$u_name" | jq .success  2>>/dev/null)"
    if [ "$result" == "false" ]; then
        u_name=$(echo $1 |awk '{print tolower($0)}')
    fi
    curl -s -H "X-User-Id: $userId" -H "X-Auth-Token: $authToken" -H "Content-type: application/json" "https://$server/$API?username=$u_name" | jq .user.username  2>>/dev/null  | sed 's/^"//;s/"$//'
}

# setting [true/false]
getSettings(){

    API="/api/v1/settings/$1"

    if [ $debug -eq 1 ]; then debug "$FUNCNAME $@" ; fi
    curl -s -H "X-User-Id: $userId" \
        -H "X-Auth-Token: $authToken" \
        -H "Content-type: application/json" \
        "https://$SERVER/$API" \
        | jq  '.value'
}

setSettings() {

    parameter=$1
    value=$2

    declare errCall="[err]: errCall"
    if [ $debug -eq 1 ]; then debug "$FUNCNAME $@" ; fi
    if [ $# -ne 2 ]; then echo ${errCall}; exit 1; fi
    API="/api/v1/settings/$parameter"
	curl -s -H "X-User-Id: $userId" \
    	-H "X-Auth-Token: $authToken" \
        -H "Content-type: application/json" \
        "https://$SERVER/$API" \
        -d '{"value": '$value'}' | jq .success
}

# # rest_request SERVER API PARAMETERS
# rest_request(){
#     local -n rest_PARAMETERS=${*: -1}

#     if [ $debug -eq 1 ]; then debug "$FUNCNAME $@" ; fi
#     if [ $debug -eq 0 ]; then SILIENT="-s"; else SILIENT=""; fi
#     curl "${SILIENT}" -H "X-User-Id: $userId" -H "X-Auth-Token: $authToken" -H "Content-type: application/json" https://$1/$2 ${rest_PARAMETERS[@]}
# }


# # rest_request SERVER API - without param
# rest_request_api(){
#     SILIENT="-s"
#     if [ $debug -eq 1 ]; then debug "$FUNCNAME $@" ; fi
#     curl "${SILIENT}" -H "X-User-Id: ${userId}" -H "X-Auth-Token: ${authToken}" -H "Content-type: application/json" https://${SERVER}/$1
# }

# check_oauth() {
#     API=/api/v1/users.getPresence
# 	rest_request_api $API | jq .success
# }

# get_user(){

# 	for i in "$@"; do
# 		info_api="https://$SERVER/api/v1/users.info?username=$i"
# 		if [ "$(curl -s -H "X-Auth-Token: $authToken" -H "X-User-Id: $userId" "$info_api" | jq .success)" == "true" ]; then
# 			echo "$i"
# 			return 0;
# 		fi
# 	done
# }

# get_group_curl(){
# 	if [ "$(curl -s -H "X-Auth-Token: $authToken" -H "X-User-Id: $userId" "$1" | jq .success)" == "true" ]; then
# 		echo "$i"
# 		return 0;
# 	fi
# 	return 1;
# }

# get_group(){

#     if [ $debug -eq 1 ]; then debug "$FUNCNAME $@" ; fi
# 	for i in "$@"; do
# 		info_api="https://$SERVER/api/v1/groups.info?roomName=$i"
# 		if get_group_curl "$info_api"; then return 0; fi
# 		info_api="https://$SERVER/api/v1/channels.info?roomName=$i"
# 		if get_group_curl "$info_api"; then return 0; fi
# 	done
# 	echo "invalid_room" >&2
# 	return 1;
# }

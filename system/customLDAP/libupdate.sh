# get_list_user [long] [offset], "1 hours", "1 days"
get_list_user(){

    lib_info_level $FUNCNAME $@
    LONG=$1
    get_credentinal
    check_date=$(date --date "-$LONG" +%Y-%m-%dT%H:%M:00.000Z);
    curl -s -G -H "X-Auth-Token: $auth_token" -H "X-User-Id: $user_id" -H "Accepts: application/json" \
        --data-urlencode 'fields={"username":1, "createdAt": 1}' \
        --data-urlencode 'query={"active": true, "roles": "user", "federation": null,"createdAt": {"$gt": {"$date": "'$check_date'" }}}' \
        --data-urlencode "offset=$2" https://$SERVER/api/v1/users.list \
    | jq -c .users[].username \
    | sed 's/"//g'
}

# set_permission [true/false]
get_permission(){

    local parameter=$1
    API="/api/v1/settings.public"
    curl -s -H "X-User-Id: $userId" \
        -H "X-Auth-Token: $userToken" \
        -H "Content-type: application/json" \
        "https://$SERVER/$API" \
        | jq  '.settings[]
            | select( ._id == "'$1'" )
            | .value' 2>/dev/null
}

set_permission() {

    lib_info_level $FUNCNAME $@
    parameter=$1
    value=$2

    param_value=$(get_permission $parameter)
    if [ "$param_value" != "$value" ]; then
        API="/api/v1/settings/$parameter"
        curl -s -H "X-User-Id: $userId" \
            -H "X-Auth-Token: $userToken" \
            -H "Content-type: application/json" \
            "https://$SERVER/$API" \
            -d '{"value": '$value'}' &>>/dev/null
    fi
}

#!/bin/bash

DIR=$(dirname $(readlink -f $(which $0)))
export script=1

source $DIR/../../lib/lib.sh
source $DIR/../../lib/trap.sh
source $DIR/../../lib/debug.sh
source $DIR/../../lib/users.sh
source $DIR/../../lib/date.sh
source $DIR/../../lib/mongo.sh
# source $DIR/../../lib/parameters.sh
source $DIR/libupdate.sh
source $DIR/update_photo.sh
source $DIR/update_data.sh
source $DIR/update_group.sh

# source $DIR/../../lib/connect.sh
# source $DIR/connect.sh

range="1 hour"
SERVER=rcdev.home.org
DEBUG=0
AUTH_FILE=~/rocket_auth
LOCKFILE=/tmp/update_user.lock
json=/tmp/update_user.json      # file for data
jpg=/tmp/update_user.jpg        # file for photo
tmp=/tmp/update_user.tmp        # tmp file
mail_pattern=$DIR/mail_pattern
u_name=$1

if ! [ -z $2 ]; then
    echo "ERROR: write only 1 user"; exit 1;
fi

trap_protector $LOCKFILE 1>&2

date +%d-%m-%Y\ %T\ %Z

source $DIR/../rest_auth/rest_auth.sh $SERVER
userId=$(cut -b 1-17 "${AUTH_FILE}" 2>>/dev/null)
userToken=$(cut -b 19-62 "${AUTH_FILE}" 2>>/dev/null)

if [ -z $1 ]; then
    step=60
    count=(one); while [ ${#count[@]} -ne 0 ]; do
        offset=$(($offset + $step))
        count=($(get_list_user "$range" $offset))
        users+=(${count[@]})
        # echo -n .
    done
else
    users+=($u_name)
fi

check_string users
parameter="Accounts_AllowUserAvatarChange"
set_permission $parameter true
parameter="Accounts_AllowRealNameChange"
set_permission $parameter true

count=0
{
    echo "NUM: USER: PHOTO: DATA:"
    for u in ${users[@]}; do
        ((count++))
        echo -n "$count. $u: "
        # echo -n "$(update_photo $u) "
        # echo "$(update_data $u)"
        update_group_ldap $u
        if [ -z $1 ]; then echo; fi
    done
 } | column -t

parameter="Accounts_AllowUserAvatarChange"
set_permission $parameter false
parameter="Accounts_AllowRealNameChange"
set_permission $parameter false

# groups add
# API=
# if [ group.private ]; then; else; fi

# rm $tmp $json $jpg
rm $LOCKFILE

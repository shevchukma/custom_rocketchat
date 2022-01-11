#/bin/bash

DIR=$(dirname $(readlink -f $(which $0)))

source $DIR/../../lib/lib.sh
source $DIR/../../lib/date.sh
source $DIR/../../lib/trap.sh
source $DIR/../../lib/debug.sh
source $DIR/../../lib/mongo.sh
source $DIR/../../lib/connect.sh
source $DIR/connect.sh

LOCKFILE=/tmp/$(basename $0).lock
DEBUG=0

trap_protector $LOCKFILE 1>&2

connects=($(lib_arr_to_arr connect1 connect2 connect3))
lib_exit_if_zero connects

m_primary=$(get_connect primary ${connects[@]})
m_secondary=$(get_connect secondary ${connects[@]})
#...

rm $LOCKFILE

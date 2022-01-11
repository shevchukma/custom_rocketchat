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

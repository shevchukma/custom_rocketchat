#!/bin/bash
# shellcheck disable=SC1090,1091,2120,2005,2026,1079,2128

include() {
	if [ -f "$1" ]; then source "$1"; else echo "${NO_FILE} $1" ; exit 0; fi
}

rootpath() { cd -- "$( dirname -- "$(readlink -f "$0")")" &> /dev/null && git rev-parse --show-toplevel; }
declare rootPath="$(rootpath)";
declare scriptPath="${rootPath}/system/removeReadReceipt";
if [ -f "${rootPath}/.env" ]; then source "${rootPath}/.env"; fi
if [ -f "${scriptPath}/.env" ]; then source "${scriptPath}/.env"; fi

# get lib
include "${rootPath}/lib/debug.sh";
include "${rootPath}/lib/trap.sh";
include "${rootPath}/lib/mongo.sh";
include "${rootPath}/lib/date.sh";


trap_protector $lockfile

# declare mongoDates=($(date_get_mongo_ignore ${dates[@]}))
declare mongoDates=($(date_get_mongo_ignore $(date --date "-$long days"  +%d.%m.%Y)))
declare query='{"ts": {$lt: ISODate("'${mongoDates[1]}'")}}'
declare command='db.rocketchat_message_read_receipt.remove('$query')'
mongoCommand master command

exit_with_rmlock

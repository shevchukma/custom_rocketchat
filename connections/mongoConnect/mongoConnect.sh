#!/bin/bash
# shellcheck disable=SC1090,2120,2005,2026,1079,2128,2154
# script export 'master' and 'secondary' connects to db

rootpath() { cd -- "$( dirname -- "$(readlink -f "$0")")" &> /dev/null && git rev-parse --show-toplevel; }
declare rootPath="$(rootpath)";
declare scriptPath="${rootPath}/connections/mongoConnect"
if [ -f "${rootPath}/.env" ]; then source "${rootPath}/.env"; fi
if [ -f "${scriptPath}/.env" ]; then source "${scriptPath}/.env"; fi

include "${rootPath}/lib/debug.sh"

i=1
if [ $debug -eq 1 ]; then debug $(basename $0) $@; fi
num="$(cat $mongoConnectFile | wc -l)"
if [ $num -eq 0 ]; then echo "$errEmpty"; exit; fi;
while [ $i -le $num ]; do
	declare connect="$(sed -n ''$i' {s/--quiet//;p}' "$mongoConnectFile")"
	connect="$connect --quiet"
	if [ "$(echo "rs.isMaster().ismaster" | $connect 2>/dev/null | grep -Ev 'CONTROL|NETWORK')"  == "true" ]; then
		master="$connect"; export master;
	elif [ "$(echo "db.hello().secondary"  | $connect 2>/dev/null | grep -Ev 'CONTROL|NETWORK')" == "true" ]; then
		secondary="$connect"; export secondary;
	fi
	i=$(($i +1))
done

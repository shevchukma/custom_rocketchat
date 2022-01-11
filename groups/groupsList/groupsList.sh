#!/bin/bash

rootpath() { cd -- "$( dirname -- "$(readlink -f "$0")")" &> /dev/null && git rev-parse --show-toplevel; }
declare rootPath="$(rootpath)";
declare scriptPath="${rootPath}/groups/groupsList"
if [ -f "${rootPath}/.env" ]; then source "${rootPath}/.env"; fi
if [ -f "${scriptPath}/.env" ]; then source "${scriptPath}/.env"; fi

include "${rootPath}/lib/debug.sh"
include "${rootPath}/lib/trap.sh"
include "${rootPath}/lib/mongo.sh"
include "${rootPath}/connections/mongoConnect/mongoConnect.sh";

trap_protector $lockfile

for i in $@; do
	echo "$i:"
	SEARCH='{"username":"'$i'"}'
	declare command='db.users.aggregate([
						{$match: '$SEARCH'},
						{$lookup: {from: "rocketchat_room",localField: "__rooms", foreignField: "_id", as: "room"}},
						{$unwind: "$room"},
						{$project: { "room.name": 1}},
						{$sort: {"room.name": 1}}
					]).forEach(function (room) {print(room.room.name)})'
	mongoCommand secondary command || echo -e "$errRequest" for \""${i}"\"
	echo ""
	if [ ${#users[@]} -gt 1 ]; then echo; fi
done

exit_with_rmlock

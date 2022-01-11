#!/bin/bash
# Удаление отключенных пользователей сервера ${SERVER} полследный вход в систему которых более ${LONG} дней
# log file будет записан в указанный путь

rootpath() { cd -- "$( dirname -- "$(readlink -f "$0")")" &> /dev/null && git rev-parse --show-toplevel; }
rootPath="$(rootpath)";
if [ -f "${rootPath}/.env" ]; then source "${rootPath}/.env"; fi
declare scriptPath="${rootPath}/system/fixUserInvitedUser/";
if [ -f "${scriptPath}/.env" ]; then source "${scriptPath}/.env"; fi

# get lib
include "${rootPath}/lib/debug.sh";
include "${rootPath}/lib/trap.sh";
include "${rootPath}/connections/mongoConnect/mongoConnect.sh";
include "${rootPath}/lib/mongo.sh";

trap_protector $lockfile

declare command='db.users.updateMany({roles: {$all: ["user", "invited-user"]}},{$set :{roles:["user"]}})'
mongoCommand master command

exit_with_rmlock

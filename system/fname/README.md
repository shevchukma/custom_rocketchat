# fname.sh

Bash scrpit for update **rocketchat_subscription.fname**  
Base on this code [bhdung, rocket.chat_19046](https://github.com/RocketChat/Rocket.Chat/issues/19046#issuecomment-730822814)

## Problem

Not work full name in private and group chat

## links problem

[rocket.chat_19046](https://github.com/RocketChat/Rocket.Chat/issues/19046)  
[rocket.chat_23093](https://github.com/RocketChat/Rocket.Chat/issues/23093)  
[rocket.chat_22647](https://github.com/RocketChat/Rocket.Chat/issues/22647)

## Description

```sh
#This script get two parameter from secondary node mongodb to object array, 
#this field `_id` in _db.rocketchat_subscription_ and field `name` in _db.users_ *only* for strings, 
#in which *rocketchat_subscription[].fname != users[].name*, and then updates this strings on primary node

#! Backup your database, and check script an testserver

git clone https://github.com/budakovda/custom_rocketchat
cd custom_rocketchat/rocketchat/fname
echo 'connect1="mongo rocketchat --host 192.168.100.105"' >connect.sh
echo 'connect2="mongo rocketchat --host 192.168.100.105 --port 27018"'>>connect.sh
echo 'connect3="mongo rocketchat --host 192.168.100.105 --port 27019"'>>connect.sh # Optionally, arbiter not use
bash fname.sh 

# TIME MODE
bash fname.sh				# full update of records
bash fname.sh 26.09.2021		# updating records only for 26.09.2021
bash fname.sh 24.09.2021  26.09.2021	# updating records for 24.09.2021 - 26.09.2021

# for watching logs
# tail -f log log.tmp

# for cron
#00 04-22 * * 1-5 bash fname.sh $(date +\%d.\%m.\%Y)
#00     * * *   * bash fname.sh

```

## Test

test results [hier](./results/README.md)

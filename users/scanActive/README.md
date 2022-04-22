# scan_active.sh

## Description

Get num message user in chats for yesterday, for date, for range date

## Steps

```sh
git clone https://github.com/shevchukma/custom_rocketchat
cd custom_rocketchat/rocketchat/users/scan.active/
echo 'connect1="mongo rocketchat --host 192.168.100.105"' >connect.sh
echo 'connect2="mongo rocketchat --host 192.168.100.105 --port 27018"'>>connect.sh
echo 'connect3="mongo rocketchat --host 192.168.100.105 --port 27019"'>>connect.sh # Optionally, arbiter not use
bash scan_active.sh [username] 
bash scan_active.sh [username] [date] 							# date format may be dd:mm:yyyy, dd:mm:yy, dd-mm-yy, dd.mm.yy
bash scan_active.sh [username] [first_date] [second_date]		# date format may be dd:mm:yyyy, dd:mm:yy, dd-mm-yy, dd.mm.yy
```

## result

```sh
[g]  - group
[p]  - private
[jc] - jitsi call
[uj] - user join
[ru] - remove user
[rm] - remove message
[rc] - room change

[username]
2      [p]: [user1],[user2]
1     [uj]: [group1]
1      [p]: [user1],[user3]
1      [g]: [group2]
```

## Notes

```sh
# num message all,
# db.rocketchat_message.find({"t": null}).forEach(function (message) {print(message.u.username)})
# db.rocketchat_message.find({"t": null, "ts" : {$gte: ISODate("2021-09-29T00:00:00.000Z"),$lt: ISODate("2021-09-29T23:59:59.999Z")}}).forEach(function (message) {print(message.u.username)})
```
## request 

```js
db.rocketchat_message.find({"u.username":"'$user'", "ts" : {$gte: ISODate("'${mongoDates[0]}'"),$lt: ISODate("'${mongoDates[1]}'")}}).
forEach(function (message) {
	var name = db.rocketchat_room.findOne({ _id : message.rid });
	if (!name.name) {
		if (!message.t) {
			print("[p] " + name.usernames)}
		else
			print("[" + message.t + "] " + name.usernames)
	}
	else {
		var name = db.rocketchat_room.findOne({ _id : message.rid });
		if (!message.t) {
			print("[g] " + name.name)
		}
		else {
			print("[" + message.t + "] " + name.name)
		}
	}
})
```

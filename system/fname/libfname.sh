# format simple array to mongo array, format: "form_mongo_arr arr"
form_mongo_arr() {

	local -n arr1=$1
	if [ $debug -eq 1 ]; then debug "$FUNCNAME $@" ; fi
	echo ${arr[@]} |
	awk '{
		for(i=1;i<=NF;i++){
			if (NF == 1)
				printf "[ \"%s\" ]", $i;
			else if ($i == $1)
				printf "[ \"%s\", ", $i;
			else if ($i == $NF)
				printf "\"%s\" ]", $i;
			else
				printf "\"%s\", ", $i}
	}'
}

form_mongo_arr_objects() {

	local -n arr1=$1
	if [ $debug -eq 1 ]; then debug "$FUNCNAME $@" ; fi
	echo ${arr[@]} |
	sed '
		s/^/[/;
		s'/$/]/';
		s/} /}, /g
	'
}

to_norm_value(){

	local val=$1
	local min=$2
	local max=$3

	if [ $debug -eq 1 ]; then debug "$FUNCNAME $@" ; fi
	if [ $val -lt $min ]; then
		val=$min;
	elif [ $val -gt $max ]; then
		val=$max;
	fi
	echo $val
}

# &arr $step &command &connect &interval
step_operation() {

	declare min_step=2
	declare max_step=50
	declare min_step_interval=0
	declare max_step_interval=30
	declare step=$2
	declare -n step_arr=$1
	declare -n step_command=$3
	declare step_interval=$5

	if [ $debug -eq 1 ]; then debug "$FUNCNAME $@" ; fi
	step=$(to_norm_value $step $min_step $max_step)
	step_interval=$(to_norm_value $step_interval $min_step_interval $max_step_interval)
	if [ $(($step % 2)) -ne 0 ]; then
		((step++))
	fi
	echo "offset: $step, interval: $step_interval"
	num=$(echo ${step_arr[@]} | awk -F '[{}]' '{printf "%d", NF }')
	j=2; while [ $j -lt $num ]; do
		offset=$(($j + $step))
		if [ $offset -gt $num ]; then step=$(($num - $j)); offset=$(($j + $step)); fi
		list_step=$(echo ${step_arr[@]} |
		awk -F '[{}]' '{
			for (i='$j'; i<=(('$offset')); i=((i + 2)))
			if (NF == '$j' + 1)
				printf "[{%s}] ",  $i;
			else if (i == '$j')
				printf "[{%s}, ",  $i;
			else if (i == '$offset')
				printf "{%s}]",  $i;
			else if (i == NF - 1)
				printf "{%s}]",  $i;
			else
				printf "{%s}, ",  $i;
		}')

		list_elem=$(echo ${list_step[@]} | awk -F '[{}]' '{printf "%d", NF/2 }')
		result_command='var list = '${list_step[@]}';
			for (i = 0; i < '$list_elem'; i++) {
				'$step_command'
			}
		'
		mongoCommand master result_command |
		awk -v flag=0 '
			/"nModified" : 1 / {
				if (flag == 0)
					printf "%s", ".";
				else {
					flag =  0; printf "%s" , "."}
			};
			!/"nModified" : 1/ {
				if (flag == 0) {
					flag = 1;
					printf "\n%s\n" ,$0
				}
				else
					printf "%s\n", $0
			}
		'
		sleep $step_interval
		j=$(($j + $step + 2))
	done
	printf "\n"

}

# Use for DEBUG. It set db.user.name for all users, if db.rochechat_subscription is actual
set_all_db_users_name() {

	t_name=$1

	if [ $debug -eq 1 ]; then debug "$FUNCNAME $@" ; fi
	command='
		var tmp_name="'$t_name'";
		db.users.find({},{_id:0, username: 1}).
		forEach(function (user) {
			print("{\"username\":\"" + user.username + "\",\"name\":\"" + tmp_name + "\"}"
	)})'
	arr=$(mongoCommand secondary command)
	num_arr=$(($(echo ${arr[@]} | awk -F '[{}]' '{printf "%d", NF }') / 2))
	users=($(form_mongo_arr_objects arr))
	command='
		var task_list ='${users[@]}';
		for (i = 0; i < '$num_arr'; i++) {
			db.users.update({
				username: task_list[i].username }, {
				$set: {
					 name: task_list[i].name
	}})}'
	mongoCommand master command |
	awk -v num=$num_arr '
		/"nModified" : 1 /{ printf "[info]: [for test] [MODIFIED: %d]\n", num;};
		/"nModified" : 0 / {printf "[info]: [for test] [NOT MODIFIED]\n";}
	'
}

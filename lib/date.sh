#!/bin/bash

allDates() {

	if [ $debug -eq 1 ]; then debug "$FUNCNAME $@" ; fi
	echo $@ |
	grep -oE '[[:digit:]]{1,2}[-\.\:][[:digit:]]{1,2}[-\.\:][[:digit:]]{1,4}' |
	awk -F '[-.:]' '$1 > 0 && $1 <= 31 && $2 > 0 && $2 <= 12 {print $0}'
}

date_parse() {

	if [ $debug -eq 1 ]; then debug "$FUNCNAME $@" ; fi
	echo $1 |
	awk \
	-v year_2=$(date +%Y| cut -b 1-2) \
	-F '[-.:]' '
	{
		if (length($1) == 1)
			print "0"$1;
		else
			print $1; printf " "
		if (length($2) == 1)
			print "0"$2;
		else
			print $2; printf " "
		if (length($3) == 1)
			print year_2"0"$3;
		else if (length($3) == 2)
			print year_2$3;
		else
			print $3;
	}'
}

date_str_to_list() {

	if [ $debug -eq 1 ]; then debug "$FUNCNAME $@" ; fi
	i=1; while [ $i -le $# ]; do
		echo ${!i} | sed 's/[.:-]/./g';
		i=$(($i + 1))
	done
}

date_range() {

	if [ $debug -eq 1 ]; then debug "$FUNCNAME $@" ; fi
	date_str_to_list $@ | sort -t \. -k 3n -k 2n -k 1n | sed '1p;$p;d'
}

date_m_lower() {

	if [ $debug -eq 1 ]; then debug "$FUNCNAME $@" ; fi
	echo ""$3"-"$2"-"$1"T00:00:00.000Z"
}

date_m_granted(){

	if [ $debug -eq 1 ]; then debug "$FUNCNAME $@" ; fi
	echo ""$3"-"$2"-"$1"T23:59:59.999Z"
}

# range[]: [0] - min date, [1] - max date
date_get_mongo() {


	if [ $debug -eq 1 ]; then debug "$FUNCNAME $@" ; fi
	all_dates=($(allDates $@))
	if [ ${#all_dates[@]} -eq 0 ]; then
	 	echo "Please write date [dd:mm:yyyy] format" 1>&2
	 	exit_with_rmlock
	else
		range=($(date_range ${all_dates[@]}))
		date_m_lower $(date_parse ${range[0]})
		date_m_granted $(date_parse ${range[1]})
	fi
}

date_get_mongo_ignore(){

	if [ $debug -eq 1 ]; then debug "$FUNCNAME $@" ; fi
	all_dates=($(allDates $@))
	if [ ${#all_dates[@]} -eq 0 ]; then
		echo ""
	else
		range=($(date_range ${all_dates[@]}))
		date_m_lower $(date_parse ${range[0]})
		date_m_granted $(date_parse ${range[1]})
	fi
}

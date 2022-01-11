get_photo() {

	lib_info_level $FUNCNAME "$@"
	if [ -z "$photo" ]; then
		# AD answer to request, default port 636

		# ldapsearch -x -b "OU=[OU],DC=[DC],DC=[DC]" -H ldap://[ip_srv] -D "[user_ldap]]@[domain]]" -W "(&(objectCategory=Person)(sAMAccountName=[need_user]))" |
		# $ldap | sed -z 's/\n //g' | awk '/photo/ {print $2}' | base64 -d >"$JPEG"
		# ldap="/bin/cat ~/$user.txt"
		# $ldap | sed -z 's/\n //g' | awk '/photo/ {print $2}' | base64 -d >"$JPEG"
		cp $photo $JPEG
	else
		if [[ -f "$photo" ]]; then
			# may be config base64 file
			# cat file | sed -z 's/\n //g' | awk '/photo/ {print $2}' | base64 -d >"$photo" > "$JPEG"
			cat "$photo" > "$JPEG"
		else
			echo $NOT_FILE $JPEG;
			exit_with_rmlock;
		fi
	fi
	correct_photo
}

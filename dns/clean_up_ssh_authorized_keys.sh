#!/bin/bash
# vim: ts=4:sw=4

. ~/plescripts/plelib.sh
. ~/plescripts/global.cfg
EXEC_CMD_ACTION=EXEC

typeset	-r	ME=$0
typeset	-r	PARAMS="$*"

typeset	-r	str_usage=\
"Usage : $ME"

while [ $# -ne 0 ]
do
	case $1 in
		-emul)
			EXEC_CMD_ACTION=NOP
			shift
			;;

		-h|-help|help)
			info "$str_usage"
			LN
			exit 1
			;;

		*)
			error "Arg '$1' invalid."
			LN
			info "$str_usage"
			exit 1
			;;
	esac
done

must_be_executed_on_server $infra_hostname

typeset	-r	aut_file=/root/.ssh/authorized_keys

typeset	-r	domain=$(hostname -d)

typeset -i	nr_hosts_removed=0

while read -r f1 f2 from
do
	host=${from##*@}
	info -n "$(printf "%-18s" $host)"
	if grep -q "$host" /var/named/reverse.$domain
	then
		info -f " [$OK]"
	else
		info -f "[${RED}removed${NORM}]"
		exec_cmd -c "sed -i "/$host/d" $aut_file"
		((++nr_hosts_removed))
	fi
	LN
done<$aut_file

info "$nr_hosts_removed hosts removed."

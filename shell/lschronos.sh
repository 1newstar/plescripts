#!/bin/bash
# vim: ts=4:sw=4

. ~/plescripts/plelib.sh
. ~/plescripts/global.cfg
EXEC_CMD_ACTION=EXEC

typeset	-r	ME=$0
typeset	-r	PARAMS="$*"

typeset	-r	str_usage=\
"Usage :
$ME
	[-d=0]     default 0 is today.
	[-all]     print all chronos.
	[-db=name] db name print all chronos and ignore date
"

typeset	-i	d=0
typeset		db=undef

while [ $# -ne 0 ]
do
	case $1 in
		-emul)
			EXEC_CMD_ACTION=NOP
			shift
			;;

		-d=*)
			d=${1##*=}
			[ $d -lt 0 ] && d=$((-$d)) || true
			shift
			;;

		-all)
			d=99
			shift
			;;

		-db=*)
			d=-1
			db=$(to_lower ${1##*=})
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

#ple_enable_log -params $PARAMS

typeset	-r	chrono_file=~/plescripts/tmp/scripts_chrono.txt

# $1 time seconds
function print_total_time
{
	info "Total cloning + software + create db : $(fmt_seconds $1)"
}

if [ ! -f $chrono_file ]
then
	error "$chrono_file not exists."
	LN
	exit 1
fi

if [ $d -eq 0 ]
then
	typeset	-r	today=$(date +%Y%m%d)
elif [[ $d -ne 99 && $d -ne -1 ]]
then
	typeset	-ri	theday=$(( $(date +%d) - d ))
	typeset	-r	today=$(date +%Y%m)$theday
fi

if [ $d -eq -1 ]
then
	filter_cmd="grep -E \".*:${db}[0-9]{0,2}.*\" $chrono_file"
elif [ $d -ne 99 ]
then # Filtre sur la date.
	filter_cmd="grep -E \"^$today\" $chrono_file"
else # Pas de filtre.
	filter_cmd="cat $chrono_file"
fi

debug "filter_cmd = '$filter_cmd'"

typeset		prev_id=undef
typeset	-i	total_time_s=0
while IFS=: read timestamp script_name id time_s time_f rem
do
	[ x"$timestamp" == x ] && continue || true

	id=$(to_lower $id)
	if [[ "$prev_id" != "$id" ]]
	then
		if [[ "$prev_id" != "${id:0:${#prev_id}}" ]]
		then
			[ $total_time_s -ne 0 ] && print_total_time $total_time_s || true
			total_time_s=0
		fi
		LN
		year=$(cut -c1-4<<<"$timestamp")
		month=$(cut -c5-6<<<"$timestamp")
		day=$(cut -c7-8<<<"$timestamp")
		prev_id=$id
		info "${UNDERLINE}$prev_id${NORM} : $year/$month/$day"
		info "    $(printf "%-30s" "Script name") | $(printf "%10s" "Time")"
		info "    $(fill - 30) | $(fill - 10)"
	fi
	info "    $(printf "%-30s" $script_name) | $(printf "%10s" "$time_f")"
	case "$script_name" in
		create_database_servers.sh|install_*|create_db.sh)
			total_time_s=total_time_s+time_s
			;;
	esac
done<<<"$(eval $filter_cmd)"
[ $total_time_s -ne 0 ] && print_total_time $total_time_s || true
LN

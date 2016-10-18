#!/bin/bash
# vim: ts=4:sw=4

. ~/plescripts/plelib.sh
. ~/plescripts/cfglib.sh
. ~/plescripts/networklib.sh
EXEC_CMD_ACTION=EXEC

. ~/plescripts/global.cfg

typeset -r ME=$0
typeset -r str_usage="Usage : $ME -db=<str>"

typeset db=undef

while [ $# -ne 0 ]
do
	case $1 in
		-db=*)
			db=$(to_lower ${1##*=})
			shift
			;;

		*)
			error "Arg '$1' invalid."
			LN
			info $str_usage
			exit 1
			;;
	esac
done

[[ $db == undef && x"$ID_DB" == x ]] && db=$ID_DB
exit_if_param_undef db

cfg_exist $db

typeset -ri max_nodes=$(cfg_max_nodes $db)

function print_node # $1 #inode
{
	typeset	-ri inode=$1

	cfg_load_node_info $db $inode

	case $cfg_db_type in
		rac)
			info "Node #$inode RAC : "
			;;

		std)
			info "Node #$inode standalone : "
			;;
	esac

	info "	Server name     ${cfg_server_name}       : ${cfg_server_ip}"
	if [ $cfg_db_type == rac ]
	then
		info "	VIP             ${cfg_server_name}-vip   : ${cfg_server_vip}"
		info "	Interco RAC     ${cfg_server_name}-rac   : ${if_rac_network}.${cfg_server_ip##*.}"
	fi

	case $cfg_luns_hosted_by in
		san)
			info "	Interco iSCSI   ${cfg_server_name}-iscsi : ${cfg_iscsi_ip}"
			;;

		vbox)
			info "	Disks hosted by VBox"
			;;

		*)
			warning "	Old cfg file."
			;;
	esac
}

function print_scan
{
	typeset -r	file=$1

	IFS=':' read scan_name vip1 vip2 vip3 < $file
	info "scan : $scan_name"
	info "       $vip1"
	info "       $vip2"
	info "       $vip3"
}

function print_disks
{
	typeset -r	file=$1
	exit_if_file_not_exist $file

	typeset -r upper_db=$(to_upper $db)
	typeset -i no_first_disk
	typeset -i no_last_disk
	typeset -i no_disks
	while IFS=':' read dg_name disk_size no_first_disk no_last_disk
	do
		if [ $dg_name = FS ]
		then
			info "FS of ${disk_size}Gb"
		else
			info "DG $dg_name :"
			typeset	-i	size=0
			typeset	-i	label_len=0
			typeset		disk_name
			typeset		label
			typeset		idisk
			for idisk in $( seq $no_first_disk $no_last_disk )
			do
				disk_name=$(printf "S1DISK%s%02d" $upper_db $idisk)
				label=$(printf "	%s  %dGb\n" $disk_name $disk_size)
				info "$label"
				label_len=${#label}
				size=size+disk_size
			done
			typeset	-i total_disks=$(( no_last_disk - no_first_disk + 1 ))
			info "$(printf "%${label_len}s %02dGb" "$total_disks disks" $size)"
			LN
		fi
	done < $file
}

for inode in $( seq $max_nodes )
do
	print_node $inode
	LN
done

if [ -f $cfg_path_prefix/$db/scanvips ]
then
	print_scan $cfg_path_prefix/$db/scanvips
	LN
fi

print_disks $cfg_path_prefix/$db/disks

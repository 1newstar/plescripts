#!/bin/bash
# vim: ts=4:sw=4

PLELIB_OUTPUT=FILE
. ~/plescripts/plelib.sh
. ~/plescripts/dblib.sh
. ~/plescripts/gilib.sh
. ~/plescripts/global.cfg
EXEC_CMD_ACTION=EXEC

typeset -r ME=$0
typeset -r str_usage=\
"Usage : $ME
	[-db_name=name]       Mandatory for DG.
	-pdb_name=name
	[-update_script_only] Met uniquement à jour le script.
	[-force]              Si le service existe, il est recréé.
"

script_banner $ME $*

typeset db_name=auto
typeset	pdb_name=undef
typeset	create_crs_resource=yes
typeset	force=no

while [ $# -ne 0 ]
do
	case $1 in
		-emul)
			EXEC_CMD_ACTION=NOP
			shift
			;;

		-db_name=*)
			db_name=${1##*=}
			shift
			;;

		-pdb_name=*)
			pdb_name=${1##*=}
			shift
			;;

		-update_script_only)
			create_crs_resource=no
			shift
			;;

		-force)
			force=yes
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

exit_if_param_undef pdb_name	"$str_usage"

must_be_user grid

typeset	-r	script_name=~/mount-dbfs-$pdb_name
[ $db_name == auto ] && db_name=$(to_lower $(extract_db_name_from $pdb_name)) || true
typeset	-r	service_name=pdb${pdb_name}_oci
typeset	-r	resource_name="pdb.${pdb_name}.dbfs"
typeset	-r	dbfs_name=staging_area
typeset -r	ora_service=$(to_lower "ora.${db_name}.${service_name}.svc")

function create_script
{
	line_separator
	info "Create script $script_name"
	exec_cmd cp	~/plescripts/db/dbfs/mount-dbfs $script_name
	exec_cmd chmod u+x $script_name
	LN

	if [ $gi_count_nodes -gt 1 ]
	then
		info "Copy script to $gi_node_list"
		for node in $gi_node_list
		do
			exec_cmd scp $script_name $node:$script_name
		done
		LN
	fi
}

function resource_exists
{
	if grep -qE "CRS-2613" <<<"$(crsctl stat res $resource_name)"
	then
		return 1	# resource not exists
	else
		return 0	# resource exits.
	fi
}

function create_local_resource
{
	if $(resource_exists $resource_name)
	then
		line_separator
		info "Resource $resource_name exists."
		if [ $force == no ]
		then
			error "Used flag -force to delete it."
			exit 1
		fi

		info "Flag -force set, delete resource."
		exec_cmd -c crsctl stop res $resource_name
		exec_cmd crsctl delete res $resource_name -f
		LN
	fi

	line_separator
	info "create local resource $resource_name"

	add_dynamic_cmd_param "-type local_resource"
	add_dynamic_cmd_param "-attr \"ACTION_SCRIPT='$script_name'"
	add_dynamic_cmd_param "     ,CHECK_INTERVAL=3600,RESTART_ATTEMPTS=10"
	add_dynamic_cmd_param "     ,START_DEPENDENCIES='pullup:always($ora_service)'"
	add_dynamic_cmd_param "     ,STOP_DEPENDENCIES='hard(intermediate:ora.${db_name}.db)'"
	add_dynamic_cmd_param "     ,SCRIPT_TIMEOUT=300\""
	exec_dynamic_cmd "crsctl add resource $resource_name"

	info "Status"
	exec_cmd crsctl stat res $resource_name -t
	LN

	info "Start $resource_name"
	exec_cmd crsctl start res $resource_name
	LN

	info "Status"
	exec_cmd crsctl stat res $resource_name -t
	LN
}

function exit_is_rac_not_administrator_managed
{
	grep -qE "Database is administrator managed" <<<"$(srvctl config database -db $db_name)"
	if [ $? -ne 0 ]
	then
		error "Work only on RAC administrator managed."
		LN
		exit 1
	fi
}

exit_if_service_not_running $db_name $pdb_name $service_name

[ $gi_count_nodes -gt 1 ] && exit_is_rac_not_administrator_managed || true

create_script

[ $create_crs_resource == yes ] && create_local_resource || true
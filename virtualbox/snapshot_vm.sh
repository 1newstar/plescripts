#!/bin/bash
# vim: ts=4:sw=4

. ~/plescripts/plelib.sh
. ~/plescripts/cfglib.sh
. ~/plescripts/virtualbox/vboxlib.sh
. ~/plescripts/global.cfg
EXEC_CMD_ACTION=EXEC

typeset	-r	ME=$0
typeset	-r	PARAMS="$*"

typeset		db=undef
typeset		server=none
typeset		snapname
typeset		action

typeset	-r	str_usage=\
"Usage :
$ME
	-db=id|-server=name
	[-take=desc]     take snapshot with current timestamp and description 'desc'.
	[-rollback=name] rollback snapshot named 'name', all modifications are cancelled.
	[-commit=name]   commit snapshot named 'name', apply all modifications.
	[-restore=name]  restore snapshot ==> rollback all modifications, and there is no need to take a new snapshot.
	[-list]          list snapshot names.
"

while [ $# -ne 0 ]
do
	case $1 in
		-emul)
			EXEC_CMD_ACTION=NOP
			shift
			;;

		-db=*)
			db=${1##*=}
			shift
			;;

		-server=*)
			server=${1##*=}
			shift
			;;

		-rollback=*)
			action=rollback
			snapname=${1##*=}
			shift
			;;

		-take=*)
			action=take
			# Correspondra à la description
			snapname=${1##*=}
			shift
			;;

		-commit=*)
			action=commit
			snapname=${1##*=}
			shift
			;;

		-restore=*)
			action=restore
			snapname=${1##*=}
			shift
			;;

		-list)
			action=list
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

function delete_snapshot
{
	line_separator
	info "VM $cfg_server_name delete snapshot $snapname"
	exec_cmd VBoxManage snapshot $cfg_server_name delete \"$snapname\"
	LN
}

function restore_snapshot
{
	line_separator
	info "VM $cfg_server_name restore snapshot $snapname"
	exec_cmd VBoxManage snapshot $cfg_server_name restore \"$snapname\"
	LN
}

function take_snapshot
{
	line_separator
	info "VM $cfg_server_name take snapshot $snapname"
	exec_cmd VBoxManage snapshot $cfg_server_name			\
						take \"$(date +"%Y/%m/%d %Hh%M")\"	\
						--description \"$snapname\"
	LN
}

function list_snapshots
{
	info "Snapshot for VM $cfg_server_name"
	exec_cmd VBoxManage snapshot $cfg_server_name list --machinereadable
	LN
}

#ple_enable_log -params $PARAMS

case $action in
	rollback|take|commit|restore)
		if [ x"$snapname" == x ]
		then
			error "Snapshot name missing."
			LN
			info "$str_usage"
			LN
			exit 1
		fi
		;;
	list)
		:
		;;
	*)
		error "no action."
		LN
		info "$str_usage"
		LN
		exit 1
esac

if [ $server == none ]
then
	if [ $db == undef ]
	then
		error "-db or -server missing."
		LN
		info "$str_usage"
		LN
		exit 1
	fi

	cfg_exists $db

	typeset	-ri	max_nodes=$(cfg_max_nodes $db)
else
	typeset	-ri	max_nodes=1
fi

typeset	restart_vm=no
case $action in
	rollback|take)
		if [ $server == none ]
		then
			cfg_load_node_info $db 1
			if vm_running $cfg_server_name
			then
				line_separator
				restart_vm=yes
				exec_cmd stop_vm $db
				LN
			fi
		elif vm_running $server
		then
			line_separator
			restart_vm=yes
			exec_cmd stop_vm $server
			LN
		fi
		;;
esac

for (( inode = 1; inode <= max_nodes; ++inode ))
do
	if [ $server == none ]
	then
		cfg_load_node_info $db $inode
	else
		cfg_server_name=$server
	fi

	vm_list="$vm_list $cfg_server_name"
	case $action in
		rollback)
			restore_snapshot
			delete_snapshot
			;;
		take)
			take_snapshot
			;;
		commit)
			delete_snapshot
			;;
		restore)
			restore_snapshot
			;;
		list)
			list_snapshots
			;;
	esac
done

if [ $restart_vm == yes ]
then
	line_separator
	if [ $server == none ]
	then
		exec_cmd start_vm -lsvms=no
	else
		exec_cmd start_vm -server=$server -lsvms=no
	fi
fi

case $action in
	rollback)
		info "VM :$vm_list rollback done, snapshot $snapname deleted."
		LN
		;;
	commit)
		info "VM :$vm_list commit done, all changes has been applied."
		LN
		;;
	restore)
		info "VM :$vm_list restore done, all changes has been cancelled."
		list_snapshots
		LN
		;;
	take)
		info "VM :$vm_list snapshot $snapname taken."
		LN
		;;
esac

#!/bin/bash
# vim: ts=4:sw=4

. ~/plescripts/plelib.sh
. ~/plescripts/dblib.sh
. ~/plescripts/global.cfg
EXEC_CMD_ACTION=EXEC

typeset -r ME=$0
typeset -r str_usage=\
"Usage : $ME
	[-with_standby]
"

script_banner $ME $*

typeset	with_standby=no

while [ $# -ne 0 ]
do
	case $1 in
		-emul)
			EXEC_CMD_ACTION=NOP
			shift
			;;

		-with_standby)
			with_standby=yes
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

exit_if_ORACLE_SID_not_defined

# return 0 if RAC One Node, else 1
function is_rac_one_node
{
	srvctl status database -db $db| grep -q "Online relocation: INACTIVE"
}

exec_cmd "cd ~/plescripts/db"
LN

# Si le block change tracking est déjà activé le script n'est pas
# interrompu.
exec_cmd -c "rman target sys/$oracle_password	\
				@rman/enable_block_change_tracking.sql"
LN

typeset -r DATA="$(orcl_parameter_value "db_create_file_dest")"

if is_rac_one_node
then
	typeset -r db_name="$(orcl_parameter_value "db_name")"
	typeset -r snap=$DATA/$db_name/snapshot_ctrl_file.f
else
	typeset -r snap=$DATA/$ORACLE_SID/snapshot_ctrl_file.f
fi

exec_cmd "rman target sys/$oracle_password	\
				@rman/set_config.rman using \"'$snap'\""
LN

if [ $with_standby == yes ]
then
	exec_cmd "rman target sys/$oracle_password \
				@rman/ajust_config_for_dataguard.rman"
	LN
fi

exec_cmd "cd -"
LN

info "Configuration done."
info "Backup script : rman/image_copy.rman"
LN

#!/bin/bash
# vim: ts=4:sw=4

. ~/plescripts/plelib.sh
. ~/plescripts/gilib.sh
. ~/plescripts/global.cfg
EXEC_CMD_ACTION=EXEC

typeset -r ME=$0

typeset -r str_usage=\
"Usage : $ME -pdb_name=name"

typeset pdb_name=undef

while [ $# -ne 0 ]
do
	case $1 in
		-emul)
			EXEC_CMD_ACTION=NOP
			shift
			;;

		-pdb_name=*)
			pdb_name=${1##*=}
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

must_be_user oracle

exit_if_param_undef pdb_name "$str_usage"

typeset	-r	dbfs_cfg_file=~/${pdb_name}_dbfs.cfg

if [ ! -f $dbfs_cfg_file ]
then
	echo "Error file $dbfs_cfg_file not exists."
	exit 1
fi

. $dbfs_cfg_file

line_separator
execute_on_all_nodes_v2 -c "fusermount -u /mnt/$pdb_name"
LN

sqlplus -s $dbfs_user/$dbfs_password@$service<<EOSQL
prompt drop filesystem DBFS $dbfs_name
@?/rdbms/admin/dbfs_drop_filesystem.sql $dbfs_name
EOSQL
LN

sqlplus -s sys/Oracle12@$service as sysdba<<EOSQL
prompt drop user $dbfs_user
drop user $dbfs_user cascade;
prompt drop tbs $dbfs_tbs
drop tablespace $dbfs_tbs including contents and datafiles;
EOSQL
LN

line_separator
execute_on_all_nodes_v2 'sed -i "/WALLET_LOCATION/d" $TNS_ADMIN/sqlnet.ora'
execute_on_all_nodes_v2 'sed -i "/SQLNET.WALLET_OVERRIDE/d" $TNS_ADMIN/sqlnet.ora'
LN

#	Ce n'est pas utile, mais ca ma sert de mémo.
fake_exec_cmd mkstore -wrl $ORACLE_HOME/oracle/wallet -deleteCredential $service
mkstore -wrl $ORACLE_HOME/oracle/wallet -deleteCredential $service<<EOP
$oracle_password
EOP
LN

execute_on_all_nodes_v2 "rm -f $dbfs_cfg_file"
LN

execute_on_all_nodes_v2 "rm -rf $ORACLE_HOME/oracle/wallet"
LN

info "Done."
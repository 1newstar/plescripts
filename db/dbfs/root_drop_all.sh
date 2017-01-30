#!/bin/bash
# vim: ts=4:sw=4

PLELIB_OUTPUT=FILE
. ~/plescripts/plelib.sh
. ~/plescripts/gilib.sh
. ~/plescripts/global.cfg
EXEC_CMD_ACTION=EXEC

typeset -r ME=$0
typeset -r str_usage=\
"Usage :
$ME
\t[-uninstall_fuse] uninstall fuse
"

script_banner $ME $*

typeset uninstall_fuse=no

while [ $# -ne 0 ]
do
	case $1 in
		-emul)
			EXEC_CMD_ACTION=NOP
			shift
			;;

		-uninstall_fuse)
			uninstall_fuse=yes
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

must_be_user root

typeset -ri count_dbfs_res=$(crsctl stat res -t | grep -E ".*\.dbfs$" | wc -l)
if [ $count_dbfs_res -ne 0 ]
then
	error "$count_dbfs_res dbfs resources exists"
	exec_cmd "crsctl stat res -t | grep -E '.*\.dbfs$'"
	LN
	info "Execute with oracle : drop_dbfs.sh"
	LN
	exit 1
fi

if [ $uninstall_fuse == yes ]
then
	line_separator
	execute_on_all_nodes "rm -f /etc/ld.so.conf.d/usr_local_lib.conf"
	LN

	line_separator
	typeset	-r	rel=$(cut -d. -f1-2<<<"$oracle_release")
	typeset	-r	ver=$(cut -d. -f1<<<"$oracle_release")
	execute_on_all_nodes rm -f /usr/local/lib/libclntsh.so.$rel
	execute_on_all_nodes rm -f /usr/local/lib/libnnz$ver.so
	execute_on_all_nodes rm -f /usr/local/lib/libclntshcore.so.$rel
	execute_on_all_nodes rm -f /usr/local/lib/libfuse.so
	execute_on_all_nodes ldconfig
	LN

	line_separator
	execute_on_all_nodes "rm -f /sbin/mount.dbfs"
	LN
fi


if [ $uninstall_fuse == yes ]
then
	line_separator
	execute_on_all_nodes yum -y remove fuse fuse-libs
	LN
fi

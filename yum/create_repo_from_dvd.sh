#!/bin/bash
# vim: ts=4:sw=4

. ~/plescripts/plelib.sh
. ~/plescripts/global.cfg
EXEC_CMD_ACTION=EXEC

typeset -r ME=$0
typeset -r PARAMS="$*"

typeset	release=undef
typeset enable_repo=yes

typeset -r str_usage=\
"Usage :
$ME
	-release=DVD_R2|DVD_R3|DVD_R4
	[-enable_repo=$enable_repo]	yes or no
"

while [ $# -ne 0 ]
do
	case $1 in
		-emul)
			EXEC_CMD_ACTION=NOP
			shift
			;;

		-release=*)
			release=${1##*=}
			shift
			;;

		-enable_repo=*)
			enable_repo=${1##*=}
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

exit_if_param_invalid release "DVD_R2 DVD_R3 DVD_R4" "$str_usage"

must_be_executed_on_server $client_hostname

case $release in
	DVD_R2)
		iso_name="$iso_olinux_path/V100082-01.iso"
		;;
	DVD_R3)
		iso_name="$iso_olinux_path/V834394-01.iso"
		;;
	DVD_R4)
		iso_name="$iso_olinux_path/V921569-01.iso"
		;;
esac

info "Create repository from DVD ${release:3}"
info "DVD : $iso_name"
exit_if_file_not_exists "$iso_name"
LN

info "Attach DVD"
exec_cmd VBoxManage storageattach $infra_hostname		\
				--storagectl IDE --port 0 --device 0	\
				--medium "$iso_name"
LN

exec_cmd "ssh -t root@${infra_ip} plescripts/yum/duplicate_dvd_for_repo.sh	\
								-release=$release -enable_repo=$enable_repo"
LN

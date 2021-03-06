#!/bin/bash
# vim: ts=4:sw=4

. ~/plescripts/global.cfg
[ $rac_forcesyncntp_max_offset_ms -eq 0 ] && exit 0 || true

typeset -r ME=$0
typeset -r PARAMS="$*"

typeset -ri	max_offset_ms=$rac_forcesyncntp_max_offset_ms

if [ $master_time_server == internet ]
then
	time_server=${infra_hostname}
else
	time_server=${master_time_server}
fi

#	print abs( $1 ) to stdout
function abs
{
	typeset	val="$1"
	[ "${val:0:1}" == "-" ] && echo ${val:1} || echo $val
}

#	print integer part of $1 to stdout
function int_part
{
	cut -d. -f1<<<"$1"
}

# print offset in ms to stdout
function ntpq_read_offset_ms
{
	read	l_remote l_refid l_st l_t l_when l_pool	\
			l_reach l_delay l_offset l_jitter		\
		<<<"$(ntpq -p | tail -1)"
	abs $(int_part $l_offset)
}

# print offset in ms to stdout
function ntpdate_read_offset_ms
{
	typeset seconds
	read day month tt l_ntpdate l_ajust l_time l_server ip_ntp_server	\
			l_offset seconds l_sec <<<"$(ntpdate -b $time_server)"

	typeset	-i	offset=$(abs $(int_part $seconds))
	if [  $offset -gt 0 ]
	then
		echo "1000"
	else
		sed "s/.*\.\(...\).*/\1/"<<<"$seconds"
	fi
}

#	============================================================================
#	Test si décalage de plus de max_offset_ms
typeset -i offset_ms=10#$(ntpq_read_offset_ms)
[ $offset_ms -lt $max_offset_ms ] && status=OK || status=KO

[ $status == OK ] && exit 0 || true

[ ! -t 1 ] && exec >> /tmp/force_sync_ntp.$(date +%d) 2>&1 || true

echo "global.cfg : master_time_server = '$master_time_server'"
echo "set time_server to                '$time_server'"
echo

TT=$(date +%Hh%M)
echo "uptime : $(uptime)"
echo "$TT : $offset_ms ms < $max_offset_ms ms : $status"

if [ "$rac_forcesyncntp_log_only" == "yes" ]
then
	echo "rac_forcesyncntp_log_only == yes : do nothing."
	echo
	exit 0
fi

typeset -r lockfile=/var/lock/force_sync_ntp.lock
[[ -f $lockfile ]] && exit 0 || true
trap "{ rm -f $lockfile ; exit 0; }" EXIT
touch $lockfile

#	============================================================================
typeset	-r date_before_sync=$(date)
typeset	-r start_at=$SECONDS

#	============================================================================
echo "systemctl stop ntpd"
systemctl stop ntpd

#	============================================================================
typeset	-ri	max_loops=4	# sécurité au cas ou la synchro ne se fait pas.

typeset	-i	loop=0
typeset		time_sync=no

for loop in $( seq $max_loops )
do
	typeset -i offset_ms=10#$(ntpdate_read_offset_ms)
	[ $offset_ms -lt $max_offset_ms ] && status=OK || status=KO

	echo "Time adjusted #${loop} $offset_ms ms  < $max_offset_ms ms : $status"

	[ $status == OK ] && time_sync=yes && break	# exit loop
done

#	============================================================================
echo "systemctl start ntpd"
systemctl start ntpd

#	============================================================================
echo "Synchronization time : $(( SECONDS - start_at )) secs"
echo "Date before sync     : $date_before_sync"
echo "Date after sync      : $(date)"
echo
[ $time_sync == yes ] && exit 0 || exit 1

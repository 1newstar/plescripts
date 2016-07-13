#!/bin/bash
#	ts=4	sw=4

#	-f3-4 pour gérer le cas des RAC one node ou services managed.
instance=$(ps -ef |  grep pmon | grep -vE "MGMTDB|ASM|grep" | cut -d_ -f3-4)
if [ x"$instance" != x ]
then
    grep "$instance" /etc/oratab >/dev/null 2>&1
    if [ $? -eq 0 ]
    then
		echo "$instance"
		exit 0
    fi
fi

exit 1


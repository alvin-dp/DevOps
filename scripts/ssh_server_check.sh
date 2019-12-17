#!/bin/bash

function check_task_exec {
    #$1 - file
    #$2 - port
    #$3 - predefined task "cpu,mem"

local cpu_cmd="cat /proc/cpuinfo"
local mem_cmd="free ."
local isExecTrue=0
local ErrCode=0

case $3 in
cpu)
    local exec_cmd="$cpu_cmd"
;;
mem)
    local exec_cmd="$mem_cmd"
;;
*)
    echo "Wrong function syntax."
    exit 5;
;;
esac

for i in $(cat $1)
do
    echo "Testing host - $i..." 
    if ! [ "$(nc -w 1 -zv $i $2 2>&1 | grep -o succeeded)" = "succeeded" ]; then
        echo "Port $2 closed or no host"       
        continue;
    fi
    echo "Exec task - $3..."
    #echo "ssh -i ~/.ssh/main_key.pem centos@$i $exec_cmd"
    ssh -i ~/.ssh/main_key.pem centos@$i "$exec_cmd"
    if [ $isExecTrue = 0 ]; then
        isExecTrue=1;
    fi
done

if ! [ $isExecTrue = 1 ]; then
    echo "No alive host found."
    exit 5;
fi
}
#var
server_file_list="ssh_server_list"
port=22
tmp_file="clear_ip_address_list"
touch $tmp_file
cat /dev/null > $tmp_file

if [ $# -eq 0 ] || [ $# -gt 1 ]
then
    echo "Wrong usage. 1 argument required!"
    exit -1
fi

if ! [ "$1" == 'cpu' ] && ! [ "$1" == 'mem' ] ; then
    echo "Wrong arguments!"
    exit 1
fi

if [ ! -f "$server_file_list" ]; then
    echo "File $server_file_list not found!"
     exit 2
fi
grep -E -o "(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)" $server_file_list > $tmp_file
#ip_list=$(grep -E -o "(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)" $server_file_list)

#if [ $(echo "$ip_list" | awk 'END {print NR}') = 0 ]; then
if [ $(awk 'END {print NR}' $tmp_file) = 0 ]; then
     echo "File $server_file_list has NO valid IP addresses!"
     rm $tmp_file
     exit 3
fi 

check_task_exec $tmp_file $port $1
rm $tmp_file

#!/bin/bash

#定义检测间隔(秒), 0代表只执行一次
CHECK_INTERVAL=60

#todo
cpu_threshold=85
disk_threshold=85
mem_threshold=85
inode_threshold=85
fd_threshold=200


is_first=1
script_path=$(realpath "$0")
script_dir=$(dirname "$script_path")
sendalarm=${script_dir}"/sendalarm.sh" #todo

if [[ ! -x "$sendalarm" ]]; then
    echo $sendalarm" not exit or not exec"
    exit 3
fi

get_cmd() {
    echo $(ps -p $1 -o cmd=)
}

cpu_info() {
    data=`cat /proc/stat | awk '/cpu/{printf("%s %.2f\n"), $1, ($2+$4)*100/($2+$4+$5)}' |  awk '{print $0}'`
    echo "$data" | while read -r line; do
        cpu_name=$(echo "$line" | awk '{print $1}')
        used=$(echo "$line" | awk '{print $2}')

        if awk "BEGIN {exit !($used > $cpu_threshold)}"; then
            $sendalarm "Abnormal CPU[$cpu_name] usage[$used%]"
        fi
    done

    data=$(ps aux --sort=-%cpu | awk  -v threshold=$cpu_threshold '$3 > threshold {print}')
    if [ -n "$data" ]; then
        echo "$data" | while read -r line; do
            pid=$(echo "$line" | awk '{print $2}')
            used=$(echo "$line" | awk '{print $3}')
            cmd=$(get_cmd $pid)
            $sendalarm "Abnormal process[$pid:$cmd] cpu usage[$used%]"
        done
    fi
}

disk_info() {
    data=$(df -PThl -x tmpfs -x iso9660 -x devtmpfs -x squashfs | tail -n +2)

    echo "$data" | while read -r line; do
        file_sys=$(echo "$line" | awk '{print $1}')
        mount_point=$(echo "$line" | awk '{print $7}')
        used=$(echo "$line"|awk '{print $6}'|sed -e 's/%//g')
        if ! [[ "$used" =~ ^[0-9]+$ ]]; then
            used=0
        fi
        if [ $used -gt $disk_threshold ]; then
            $sendalarm "Abnormal Disk[$file_sys:$mount_point] usage[$used%]"
        fi
    done
}

inode_info() {
    data=$(df -iPThl -x tmpfs -x iso9660 -x devtmpfs -x squashfs | tail -n +2)

    echo "$data" | while read -r line; do
        file_sys=$(echo "$line" | awk '{print $1}')
        mount_point=$(echo "$line" | awk '{print $7}')
        used=$(echo "$line"|awk '{print $6}'|sed -e 's/%//g')
        if ! [[ "$used" =~ ^[0-9]+$ ]]; then
            used=0
        fi
        if [ $used -gt $inode_threshold ]; then
            $sendalarm "Abnormal Inode[$file_sys:$mount_point] usage[$used%]"
        fi
    done
}

mem_info() {
    mem_total=$(grep -w MemTotal /proc/meminfo|awk '{print $2/1024}')
    mem_free=$(grep -w MemAvailable /proc/meminfo|awk '{print $2/1024}')
    swap_total=$(grep -w SwapTotal /proc/meminfo|awk '{print $2/1024}')
    swap_free=$(grep -w SwapFree /proc/meminfo|awk '{print $2/1024}')
    mem_used=$(awk -v used=$mem_free -v total=$mem_total 'BEGIN { printf "%.1f", (1 - used / total) * 100 }')
    if [ $swap_total -gt 0 ]; then
        swap_used=$(awk -v used=$swap_free -v total=$swap_total 'BEGIN { printf "%.1f", (1 - used / total) * 100 }')
    else
        swap_used=0
    fi
    if awk "BEGIN {exit !($mem_used > $mem_threshold)}"; then
        $sendalarm "Abnormal Memory usage[$mem_used%]"
    fi
    if awk "BEGIN {exit !($swap_used > $mem_threshold)}"; then
        $sendalarm "Abnormal Swap usage[$swap_used%]"
    fi

    data=$(ps aux --sort=-%mem | awk  -v threshold=$mem_threshold '$4 > threshold {print}')
    if [ -n "$data" ]; then
        echo "$data" | while read -r line; do
            pid=$(echo "$line" | awk '{print $2}')
            used=$(echo "$line" | awk '{print $4}')
            cmd=$(get_cmd $pid)
            $sendalarm "Abnormal process[$pid:$cmd] memory usage[$used%]"
        done
    fi
}

zombie_info() {
    ps -eo stat|grep -w Z 1>&2 > /dev/null
    if [ $? == 0 ]; then
        data=""
        data="found "$(ps -eo stat|grep -w Z|wc -l)" zombie process on the system, detail:"
        data=$data"\\n"

        ZPROC=$(ps -eo stat,pid|grep -w Z|awk '{print $2}')
        for i in $(echo "$ZPROC"); do
            data=$data$(ps -o pid,ppid,user,stat,args -p $i | tail -n +2)"\n"
        done
        $sendalarm "$data"
    fi
}

last_reboot_shutdown_event() {
    if [ $is_first -eq 1 ]; then
        is_first=0
        reboot_event=$(last -x -F | grep reboot | head -1)
        shutdown_event=$(last -x -F | grep shutdown | head -1)
        $sendalarm "The most recent system reboot event: $reboot_event"
        $sendalarm "The most recent system shutdown event: $shutdown_event"
    fi
}

#必须root或sudo才能执行fd_info
fd_info() {
    if [ $(id -u) -eq 0 ]; then
        for pid in /proc/[0-9]*; do
            # echo $pid
            # 检查是否是目录
            if [ -d "$pid" ]; then
                # 获取进程ID
                pid_num=$(basename "$pid")
                prog_name=$(get_cmd $pid_num)
                cnt=$(ls -l /proc/$pid_num/fd/ | wc -l)
                if [ $cnt -gt $fd_threshold ]; then
                    $sendalarm "Abnormal process[$prog_name] fd count[$cnt]"
                fi
            fi
        done
    else
        $sendalarm "must be root user to run [fd_info]"
    fi
}

while true; do
    cpu_info
    mem_info
    disk_info
    inode_info
    zombie_info
    last_reboot_shutdown_event
    fd_info

    if [ $CHECK_INTERVAL -le 0 ]; then
        exit 0
    fi

    sleep "$CHECK_INTERVAL"
done
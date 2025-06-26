#!/bin/bash
#===================================================================================
#
# FILE: rtmpbee-subscriber.sh
#
# USAGE: rtmpbee-subscriber.sh [endpoint] [amount_of_subscribers] [amount_of_time_to_playback_stream]
#
# EXAMPLE: ./rtmpbee-subscriber.sh "rtmp://release-11.red5.net:1935/live/stream1" 1 60    # This will add 1 Subscriber to the stream for 60 seconds
# 
# DESCRIPTION: Creates N-number of RTMP subscribers to a given endpoint.
# Console output sent to log/rtmp_sub_N_N.log and monitored for status.
#
# OPTIONS: see function ’usage’ below
# REQUIREMENTS: ---
# BUGS: ---
# NOTES: ---
# AUTHOR: Oles Prykhodko
# COMPANY: Infrared5, Inc.
# VERSION: 1.0.0
#===================================================================================

endpoint=$1
amount=$2
timeout=$3

dir="./log/rtmp_sub"
amount_of_directories=$( (find ${dir}_* -maxdepth 1 -type d 2>/dev/null | wc -l) )
current_run_number=$((amount_of_directories+1))
current_dir="${dir}_${current_run_number}"
mkdir -p "${current_dir}"
log_file="${current_dir}/rtmp_sub"
PIDS=()

log_i() {
    log
    printf "\033[0;36m [INFO]  --- %s \033[0m\n" "${@}"
    log >> "${log_file}_main.log"
    echo " [INFO]  --- ${*}" >> "${log_file}_main.log"
}
log_s() {
    log
    printf "\033[0;32m [START] --- %s \033[0m\n" "${@}"
    log >> "${log_file}_main.log"
    echo " [START] --- ${*}" >> "${log_file}_main.log"
}
log_f() {
    log
    printf "\033[0;33m [STOP]  --- %s \033[0m\n" "${@}"
    log >> "${log_file}_main.log"
    echo " [STOP]  --- ${*}" >> "${log_file}_main.log"
}
log_w() {
    log
    printf "\033[0;34m [WARN]  --- %s \033[0m\n" "${@}"
    log >> "${log_file}_main.log"
    echo " [WARN]  --- ${*}" >> "${log_file}_main.log"
}
log_e() {
    log
    printf "\033[0;31m [ERROR] --- %s \033[0m\n" "${@}"
    log >> "${log_file}_main.log"
    echo " [ERROR]  --- ${*}" >> "${log_file}_main.log"
}
log() {
    echo -n "[$(date '+%Y-%m-%d %H:%M:%S')]"
}

if [[ -z "$endpoint" || -z "$amount" || -z "$timeout" ]]; then
    log_w "Not all arguments are set. Please check your command."
    log_w 'Example: rtspbee-subscriber.sh "rtmp://[your.red5pro-deploy.com]:1935/live/[your_stream_name]" 1 60'
    exit 1
fi

#=== FUNCTION ================================================================
# NAME: shutdown
# DESCRIPTION: Shutdown current process
#=============================================================================

function shutdown {
    local pid=$1

    for ((p=1;p<=5;p++)); do
        if ps -p "$pid" > /dev/null
        then
            kill -9 "$pid" > /dev/null 2>&1
        else
            log_f "Bee #$i --- stopped, PID(${pid})"
            break
        fi
        if [ "$p" -eq "5" ]; then
            log_w "Bee #$i --- Can't stop, PID(${pid}). Please kill this process manualy in terminal: kill ${pid}"
        fi
        sleep 0.4
    done
}

#=== FUNCTION ================================================================
# NAME: interrupt
# DESCRIPTION: Shutdown all process if script run interrupted: CTRL+C
#=============================================================================

function interrupt {
    log_w "Interrupting all process!!!"
    for index in ${!PIDS[*]}
    do
        local i=$((index+1))
        shutdown "${PIDS[${index}]}"
    done
    exit 0
}

#=== FUNCTION =======================================================================
# NAME: checkStatus
# DESCRIPTION: Check the success or failure status of the bee subscription on stream.
#====================================================================================

function checkStatus {
    local pid=$1
    local timeout=$2
    local name=$3
    local beeN=$4
    
    fail_counter=5
    success=0
    regex_fail="Output #0"
    
    for ((t=1;t<=fail_counter;t++)); do
        
        while read -r line
        do
            if [[ $line =~ $regex_fail ]]; then
                success=1
            fi
        done < "${log_file}_${name}.log"
        
        if [ $success -eq 1 ]; then
            log_s "Bee #$beeN --- Deployed. Will kill in ${timeout} seconds, PID:${pid}"
            sleep "$timeout"
            shutdown "$pid"
            break
        else
            if [ $t -eq $fail_counter ]; then
                log_w "Bee #$beeN --- Not deployed. Please check log file ${log_file}_${name}.log and target Red5 pro server!!!"
                shutdown "$pid"
            fi
            sleep 1
        fi
    done
}

echo "--------------------------------------------------" >> "${log_file}_main.log"
printf '%*s\n' "${COLUMNS:-$(tput cols)}" '' | tr ' ' -
log_i "RTMP Subscribe bees"
log_i "Red5 Pro target endpoint: $endpoint"
log_i "Amount of bees: $amount"
log_i "Time to live bees: $timeout"
printf '%*s\n' "${COLUMNS:-$(tput cols)}" '' | tr ' ' -
echo "--------------------------------------------------" >> "${log_file}_main.log"

trap 'interrupt' SIGINT SIGTERM

for ((i=1;i<=amount;i++)); do
    name="${current_run_number}_${i}"
    rm -rf "${log_file}_${name}.log"
    log_s "Bee #$i --- Deploying... Target: ${endpoint}"
    log_s "Bee #$i --- Log file: ${log_file}_${name}.log"

    ffmpeg -loglevel verbose -i "$endpoint" -t "${timeout}" -f null - 3>&1 1>"${log_file}_${name}.log" 2>&1 &
    pid=$!
    PIDS+=("${pid}")
    sleep 1
    if [ "$i" -eq "$amount" ]; then
        (checkStatus "$pid" "$timeout" "$name" "$i")
    else
        (checkStatus "$pid" "$timeout" "$name" "$i")&
    fi
    sleep 0.2
done


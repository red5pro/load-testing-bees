#!/bin/bash
#===================================================================================
#
# FILE: rtspbee-subscriber-sm.sh
#
# USAGE: rtspbee-subscriber-sm.sh [endpoint] [Nodegroup_name] [rtmp_port] [app] [streamName] [amount_of_subscribers] [amount_of_time_to_playback_in_seconds]
#
# EXAMPLE: ./rtspbee-subscriber-sm.sh red5pro.server.com my_nodegroup 8554 live stream1 1 60 
#
# DESCRIPTION: Creates N-number of RTSP subscribers to a given endpoint.
# Console output sent to log/rtmp_sm_sub_N_N.log and monitored for status.
#
# OPTIONS: see function ’usage’ below
# REQUIREMENTS: ---
# BUGS: ---
# NOTES: ---
# AUTHOR: Todd Anderson, Oles Prykhodko
# COMPANY: Infrared5, Inc.
# VERSION: 2.0.0
#===================================================================================

endpoint=$1
nodegroup_name=$2
port=$3
app=$4
stream_name=$5
amount=$6
timeout=$7

dir="./log/rtmp_sm_sub"
amount_of_directories=$( (find ${dir}_* -maxdepth 1 -type d 2>/dev/null | wc -l) )
current_run_number=$((amount_of_directories+1))
current_dir="${dir}_${current_run_number}"
mkdir -p "${current_dir}"
log_file="${current_dir}/rtmp_sm_sub"
PIDS=()

log_i() {
    log
    printf "\033[0;36m [INFO]  --- %s \033[0m\n" "${@}"
    log >> ${log_file}_main.log
    echo " [INFO]  --- ${*}" >> ${log_file}_main.log
}
log_s() {
    log
    printf "\033[0;32m [START] --- %s \033[0m\n" "${@}"
    log >> ${log_file}_main.log
    echo " [START] --- ${*}" >> ${log_file}_main.log
}
log_f() {
    log
    printf "\033[0;33m [STOP]  --- %s \033[0m\n" "${@}"
    log >> ${log_file}_main.log
    echo " [STOP]  --- ${*}" >> ${log_file}_main.log
}
log_w() {
    log
    printf "\033[0;34m [WARN]  --- %s \033[0m\n" "${@}"
    log >> ${log_file}_main.log
    echo " [WARN]  --- ${*}" >> ${log_file}_main.log
}
log_e() {
    log
    printf "\033[0;31m [ERROR] --- %s \033[0m\n" "${@}"
    log >> ${log_file}_main.log
    echo " [ERROR]  --- ${*}" >> ${log_file}_main.log
}
log() {
    echo -n "[$(date '+%Y-%m-%d %H:%M:%S')]"
}

if [[ -z "$nodegroup_name" || -z "$endpoint" || -z "$port" || -z "$app" || -z "$stream_name" || -z "$amount" || -z "$timeout" ]]; then
    log_w "Not all arguments are set. Please check your command."
    log_w "USAGE: ./rtspbee-subscriber-sm.sh [endpoint] [Nodegroup_name] [rtsp_port] [app] [streamName] [amount_of_subscribers] [amount_of_time_to_playback_in_seconds]"
    log_w "Example: ./rtspbee-subscriber-sm.sh your.red5pro-deploy.com your_nodegroup_name 8554 live stream1 10 10 "
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
    local file=$3
    local name=$4
    local beeN=$5
    
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
            shutdown "$pid" "$file" "$name"
            break
        else
            if [ $t -eq $fail_counter ]; then
                log_w "Bee #$beeN --- Not deployed. Please check log file ${log_file}_${name}.log"
                shutdown "$pid" "$file" "$name"
            fi
            sleep 1
        fi
    done
}

echo "--------------------------------------------------" >> ${log_file}_main.log
printf '%*s\n' "${COLUMNS:-$(tput cols)}" '' | tr ' ' -
log_i "RTSP Subscribe bees"
log_i "Red5 Stream Manager target server: $endpoint"
log_i "Red5 Stream Manager nodegroup: $nodegroup_name"
log_i "Red5 Pro node target port: $port"
log_i "Stream name: $stream_name"
log_i "Amount of Subscriber: $amount"
log_i "Time to live bees subscriber: $timeout"
printf '%*s\n' "${COLUMNS:-$(tput cols)}" '' | tr ' ' -
echo "--------------------------------------------------" >> ${log_file}_main.log

trap 'interrupt' SIGINT SIGTERM

for ((i=1;i<=amount;i++)); do
    edge_node=$(curl -s --location --request GET "https:///$endpoint/as/v1/streams/stream/$nodegroup_name/subscribe/live/$stream_name?strict=false&endpoints=1" --header 'Content-Type: application/json' | jq -r '.[0].serverAddress' 2>/dev/null) 
    
    if [[ -z "$edge_node" ]]; then
        log_w "No Edge node found for subscribing stream: $stream_name."
        exit 1
    fi

    stream_endpoint="rtsp://${edge_node}:${port}/${app}/${stream_name}"
    name="${current_run_number}_${i}"
    rm -rf "${log_file}_${name}.log"
    log_s "Bee #$i --- Deploying... Target: ${stream_endpoint}"
    log_s "Bee #$i --- Log file: ${log_file}_${name}.log"

    ffmpeg -loglevel verbose -rtsp_transport tcp -i "$stream_endpoint" -t "${timeout}" -f null - 3>&1 1>"${log_file}_${name}.log" 2>&1 &
    pid=$!
    PIDS+=("${pid}")
    sleep 1
    if [ "$i" -eq "$amount" ]; then
        (checkStatus "$pid" "$timeout" "$file" "$name" "$i")
    else
        (checkStatus "$pid" "$timeout" "$file" "$name" "$i")&
    fi
    sleep 0.2
done

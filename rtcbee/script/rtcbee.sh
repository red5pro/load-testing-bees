#!/bin/bash
#===================================================================================
#
# FILE: rtcbee.sh
#
# USAGE: rtcbee.sh [endpoint] [app] [streamName] [amount of streams to start] [amount of time to playback] [old scenario true/false]
#
# EXAMPLE: ./rtcbee.sh "your.red5pro-deploy.com" live stream1 10 10 false
#
# DESCRIPTION: Creates N-number of headless WebRTC-based subscriptions to a live stream.
# Console output sent to log/rtc_sub_streamname_N.log and monitored for status.
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
app=$2
stream_name=$3
amount=$4
timeout=$5
mode=$6 # true (enable old scenario 1 after 1)

log_file="log/rtc_sub"
DEBUG_PORT_START=$(((RANDOM % 10000)+10000));

mkdir -p log
PIDS=()
log_i() {
    log
    printf "\033[0;36m [INFO]  --- %s \033[0m\n" "${@}"
}
log_s() {
    log
    printf "\033[0;32m [START] --- %s \033[0m\n" "${@}"
}
log_f() {
    log
    printf "\033[0;33m [STOP]  --- %s \033[0m\n" "${@}"
}
log_w() {
    log
    printf "\033[0;31m [WARN]  --- %s \033[0m\n" "${@}"
}
log() {
    echo -n "[$(date '+%Y-%m-%d %H:%M:%S')]"
}

#=== FUNCTION ================================================================
# NAME: shutdown
# DESCRIPTION: Shutdown current process
#=============================================================================

function shutdown {
    local pid=$1
    local beeN=$2
 
    for ((p=1;p<=5;p++)); do
        if ps -p "$pid" > /dev/null
        then
            kill -9 "$pid" > /dev/null 2>&1
        else
            log_f "Bee #${beeN} --- stopped, PID(${pid})"
            break
        fi
        if [ "$p" -eq "5" ]; then
            log_w "Bee #${beeN} --- Can't stop, PID(${pid}). Please kill this process manualy in terminal: kill ${pid}"
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
        shutdown "${PIDS[${index}]}" "${i}"
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
    
    fail_counter=10
    success=0
    regex_fail="Subscribe\.Start"
    
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
            shutdown "$pid" "${beeN}"
            break
        else
            if [ $t -eq $fail_counter ]; then
                log_w "Bee #$beeN --- Not deployed. Please check log file ${log_file}_${name}.log and target Red5 pro server!!!"
                sleep $((timeout-fail_counter))
                shutdown "$pid" "${beeN}"
            fi
            sleep 1
        fi
    done
}


# Dispatch.
function start_bees {
    name="${stream_name}_${i}"
    rm -rf "${log_file}_${name}.log"
    debug_port=$((DEBUG_PORT_START + i))
    chromium-browser --autoplay-policy=no-user-gesture-required --user-data-dir=/tmp/chrome"$(date +%s%N)" --headless --disable-gpu --mute-audio --remote-debugging-port=$debug_port $endpoint_str 3>&1 1>"${log_file}_${stream_name}_${i}.log" 2>&1 &
    pid=$!
    PIDS+=("${pid}")
    sleep 1
    if [ "$i" -eq "$amount" ]; then
        (checkStatus "$pid" "$timeout" "$name" "$i")
    else
        (checkStatus "$pid" "$timeout" "$name" "$i")&
    fi
    sleep 1
}


target="https://${endpoint}/${app}/viewer.jsp?host=${endpoint}&stream=${stream_name}"

printf '%*s\n' "${COLUMNS:-$(tput cols)}" '' | tr ' ' -
log_i "RTC Subscribe bees"
log_i "Red5 Pro target server: $endpoint"
log_i "Red5 Pro target URL: $url_endpoint"
log_i "Stream name: $stream_name"
log_i "Amount of bees $amount"
log_i "Time to live bees: $timeout"
log_i "Mode (Old scenario) : $mode"
printf '%*s\n' "${COLUMNS:-$(tput cols)}" '' | tr ' ' -

trap 'interrupt' SIGINT

if [[ "$mode" == "true" ]]; then
    log_i "Enable old scenario 1 after 1"
    endpoint_str+="$target"
    for ((k=1;k<=amount;k++)); do
        i=$(($i+1))
        log_s "Bee #$i --- Deploying +1 RTC connection... Target: ${target}"
        start_bees
    done
else
    while [ $amount -gt 0 ]
    do
        i=$(($i+1))
        if [[ $amount -gt 40 ]]; then
            for ((t=1;t<=40;t++)); do
                endpoint_str+="$target "
            done
            log_s "Bee #$i --- Deploying +40 RTC connections... Target: ${target}"
            start_bees
            endpoint_str=""
            amount=$(($amount-40))
        else
            for ((z=1;z<=amount;z++)); do
                endpoint_str+="$target "
            done
            log_s "Bee #$i --- Deploying +${amount} RTC connections... Target: ${target}"
            start_bees
            endpoint_str=""
            amount=0
        fi
    done
fi

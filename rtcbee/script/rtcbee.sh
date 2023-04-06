#!/bin/bash
#===================================================================================
#
# FILE: rtcbee.sh
#
# USAGE: rtcbee.sh [endpoint] [amount of streams to start] [amount of time to playback] ]
#
# EXAMPLE: ./rtcbee.sh "https://<RED5PRO-SERVER-HOST>/live/viewer.jsp?host=<RED5PRO-SERVER-HOST>&stream=stream1" 5 30
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
amount=$2
timeout=$3
mode="true" # true (enable old scenario 1 after 1)

# The latest versions of chromium-browser can't support multiple tabs in headless mode.  
# ERROR: Multiple targets are not supported
# https://chromium.googlesource.com/chromium/src/+/master/headless/app/headless_shell.cc
# Variable 'mode' should be set to 'true'

if [ "$mode" != "true" ] ; then
    mode="false"
fi

work_dir=$(pwd)
dir="$work_dir/log/rtc_sub"
amount_of_directories=$(find ${dir}_* -maxdepth 1 -type d | wc -l)
current_dir_number=$((amount_of_directories+1))
current_dir="${dir}_${current_dir_number}"
mkdir -p "${current_dir}"
log_file="${current_dir}/rtc_sub"

DEBUG_PORT_START=$(((RANDOM % 10000)+10000));

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
            log_f "Bee #${beeN} --- stopped, PID(${pid}), Log file ${log_file}_${beeN}.log"
            break
        fi
        if [ "$p" -eq "5" ]; then
            log_e "Bee #${beeN} --- Can't stop, PID(${pid}). Please kill this process manualy in terminal: kill ${pid}"
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
    local beeN=$2
    local tabs=$3

    fail_counter=15
    regex_fail="Subscribe\.Start"

    for ((t=1;t<=fail_counter;t++)); do
        success=0

        while read -r line
        do
            if [[ $line =~ $regex_fail ]]; then
                success=$((success+1))
            fi
        done < "${log_file}_${beeN}.log"

        if [ $success -eq $tabs ]; then
            log_s "Bee #$beeN --- Deployed. $success out of ${tabs} Connections(tabs). Will kill in ${timeout} seconds, PID:${pid}"
            sleep "$timeout"
            shutdown "$pid" "${beeN}"
            break
        else
            if [ $t -eq $fail_counter ]; then
                if [ $success -gt 0 ]; then
                    log_w "Bee #$beeN --- Partially Deployed. $success out of ${tabs} Connections(tabs). Will kill in ${timeout} seconds. Please check log file ${log_file}_${beeN}.log and target Red5 pro server!!!"
                    sleep $((timeout-fail_counter))
                    shutdown "$pid" "${beeN}"
                else
                    log_e "Bee #$beeN --- Not deployed. $success out of ${tabs} Connections(tabs). Please check log file ${log_file}_${beeN}.log and target Red5 pro server!!!"
                    shutdown "$pid" "${beeN}"
                fi
            fi
            sleep 1
        fi
    done
}

# Dispatch.
function start_bees {
    tabs=$1
    debug_port=$((DEBUG_PORT_START + i))
    log_file_current="${log_file}_${i}.log"
    rm -rf ${log_file_current}
    log_s "Bee #$i --- Open debug port: $debug_port"
    #--enable-logging=stderr --v=1
    chromium-browser --autoplay-policy=no-user-gesture-required --user-data-dir=/tmp/chrome"$(date +%s%N)" --headless --disable-gpu --mute-audio --window-size=1024,768 --remote-debugging-port=$debug_port $endpoint_str 3>&1 1>"${log_file_current}" 2>&1 &
    pid=$!
    PIDS+=("${pid}")
    sleep 0.1
    if [ "$i" -eq "$amount" ]; then
        (checkStatus "$pid" "$i" "$tabs")
    else
        (checkStatus "$pid" "$i" "$tabs")&
    fi
}

printf '%*s\n' "${COLUMNS:-$(tput cols)}" '' | tr ' ' -
echo "--------------------------------------------------" >> ${log_file}_main.log
log_i "RTC Subscribe bees"
log_i "Red5 Pro target URL: $endpoint"
log_i "Amount of bees $amount"
log_i "Time to live bees: $timeout"
log_i "Mode (Old scenario) : $mode"
log_i "Logs folder: $current_dir"
printf '%*s\n' "${COLUMNS:-$(tput cols)}" '' | tr ' ' -
echo "--------------------------------------------------" >> ${log_file}_main.log

trap 'interrupt' SIGINT

if [[ "$mode" == "true" ]]; then
    log_i "Enable old scenario 1 after 1"
    endpoint_str+="$endpoint"
    for ((k=1;k<=amount;k++)); do
        i=$((i+1))
        log_s "Bee #$i --- Deploying +1 RTC connection... Target: ${endpoint}"
        start_bees "1"
    done
else
    while [ "$amount" -gt 0 ]
    do
        i=$((i+1))
        if [[ $amount -gt 40 ]]; then
            for ((t=1;t<=40;t++)); do
                endpoint_str+="$endpoint "
            done
            log_s "Bee #$i --- Deploying +40 RTC connections... Target: ${endpoint}"
            start_bees "40"
            endpoint_str=""
            amount=$((amount-40))
        else
            for ((z=1;z<=amount;z++)); do
                endpoint_str+="$endpoint "
            done
            log_s "Bee #$i --- Deploying +${amount} RTC connections... Target: ${endpoint}"
            tabs=$amount
            amount=$i
            start_bees "$tabs"
            endpoint_str=""
            amount=0
        fi
    done
fi
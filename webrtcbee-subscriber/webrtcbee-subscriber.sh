#!/bin/bash
#===================================================================================
#
# FILE: webrtcbee-subscriber.sh
#
# USAGE: webrtcbee-subscriber.sh [endpoint] [server_deployment_type_standalone_or_stream_manager] [stream_name] [amount_of_subscribers] [amount_of_time_to_playback_stream_in_seconds]
#
# For STANDALONE Server Setup
# EXAMPLE: ./webrtcbee-subscriber.sh "https://your.server.com/live/viewer.jsp?host=your.server.com" standalone stream1 5 30
#
# For STREAM_MANAGER Server setup
# EXAMPLE: ./webrtcbee-subscriber.sh "https://your.server.com/red5/proxy-subscriber.html?host=your.server.com&protocol=wss&port=443&whipwhep=true&verbose=1" stream_manager stream1 5 30
#
# DESCRIPTION: Creates N-number of headless WebRTC-based subscriptions to a live stream.
# Console output sent to log/webrtc_sub_N.log and monitored for status.
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
deployment_type=$2
stream_name=$3
amount=$4
timeout=$5
mode="true" # (enable old scenario 1 after 1)

# The latest versions of chromium-browser can't support multiple tabs in headless mode.
# ERROR: Multiple targets are not supported
# https://chromium.googlesource.com/chromium/src/+/master/headless/app/headless_shell.cc
# Variable 'mode' should be set to 'true'

case "$deployment_type" in
    standalone)
        deployment_type="standalone"
        dir="./log/webrtc_sub"
        amount_of_directories=$( (find ${dir}_* -maxdepth 1 -type d 2>/dev/null | wc -l) )
        current_dir_number=$((amount_of_directories+1))
        current_dir="${dir}_${current_dir_number}"
        mkdir -p "${current_dir}"
        log_file="${current_dir}/webrtc_sub"
        ;;
    stream_manager)
        deployment_type="stream_manager"
        dir="./log/webrtc_sm_sub"
        amount_of_directories=$( (find ${dir}_* -maxdepth 1 -type d 2>/dev/null | wc -l) )
        current_dir_number=$((amount_of_directories+1))
        current_dir="${dir}_${current_dir_number}"
        mkdir -p "${current_dir}"
        log_file="${current_dir}/webrtc_sm_sub"
        ;;
    *)
        echo "Error: Invalid deployment type for parameter [server_deployment_type_standalone_or_stream_manager]: '$deployment_type'. Must be 'standalone' or 'stream_manager'."
        exit 1
        ;;
esac

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

if [[ -z "$deployment_type" || -z "$endpoint" || -z "$amount" || -z "$timeout" || -z "$stream_name"  ]]; then
    log_w "Not all arguments are set. Please check your command."
    log_w "USAGE: webrtcbee-subscriber.sh [endpoint] [server_deployment_type_standalone_or_stream_manager] [stream_name] [amount_of_subscribers] [amount_of_time_to_playback_stream_in_seconds]"
    log_w 'Example for Standalone server: webrtcbee-subscriber.sh "https://your.server.com/live/viewer.jsp?host=your.server.com" standalone stream1 1 60'
    log_w 'Example for Stream manager server: webrtcbee-subscriber.sh "https://your.server.com/red5/proxy-subscriber.html?host=your.server.com&protocol=wss&port=443&whipwhep=true&verbose=1" stream_manager stream1 1 60'
    exit 1
fi


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


function start_bees {
    tabs=$1
    debug_port=$((DEBUG_PORT_START + i))
    log_file_current="${log_file}_${i}.log"
    rm -rf ${log_file_current}
    log_s "Bee #$i --- Open debug port: $debug_port"
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
log_i "WebRTC Subscribe bees"
log_i "Red5 Pro target endpoint: $endpoint"
log_i "Server type: $deployment_type"
log_i "Stream name: $stream_name"
log_i "Amount of subscriber $amount"
log_i "Time to live subscriber: $timeout"
log_i "Mode (Old scenario) : $mode"
printf '%*s\n' "${COLUMNS:-$(tput cols)}" '' | tr ' ' -
echo "--------------------------------------------------" >> ${log_file}_main.log

trap 'interrupt' SIGINT SIGTERM

if [[ $deployment_type == "standalone" ]]; then
    endpoint_with_params="${endpoint}&stream=${stream_name}"
else
    endpoint_with_params="${endpoint}&streamName=${stream_name}"
fi

if [[ "$mode" == "true" ]]; then
    log_i "Enable old scenario 1 after 1"
    endpoint_str+="$endpoint_with_params"
    for ((k=1;k<=amount;k++)); do
        i=$((i+1))
        log_s "Bee #$i --- Deploying +1 RTC connection... Target: ${endpoint_with_params}"
        start_bees "1"
		sleep 0.5
    done
else
    while [ "$amount" -gt 0 ]
    do
        i=$((i+1))
        if [[ $amount -gt 40 ]]; then
            for ((t=1;t<=40;t++)); do
                endpoint_str+="$endpoint_with_params "
            done
            log_s "Bee #$i --- Deploying +40 RTC connections... Target: ${endpoint_with_params}"
            start_bees "40"
            endpoint_str=""
            amount=$((amount-40))
        else
            for ((z=1;z<=amount;z++)); do
                endpoint_str+="$endpoint_with_params "
            done
            log_s "Bee #$i --- Deploying +${amount} RTC connections... Target: ${endpoint_with_params}"
            tabs=$amount
            amount=$i
            start_bees "$tabs"
            endpoint_str=""
            amount=0
        fi
    done
fi

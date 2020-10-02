#!/bin/bash
#===================================================================================
#
# FILE: rtspbee-publisher.sh
#
# USAGE: rtspbee-publisher.sh [endpoint] [app] [streamName] [amount of streams to start] [amount of time to playback] [Red5pro server API key] [mp4-file]
#
# EXAMPLE: ./rtspbee-publisher.sh red5pro.server.com live todd 10 10 abc123 /path_to_video_file/bbb_480p.mp4
# LOCAL EXAMPLE: ./rtspbee-publisher.sh localhost live todd 10 10 abc123 /path_to_video_file/bbb_480p.mp4
#
# DESCRIPTION: Creates N-number of headless RTSP-based subscriptions to a live stream.
# Console output sent to log/rtspbee_N.log and monitored for status.
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
api_key=$6
file=$7

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
    local file=$2
    local name=$3
    curl --silent "http://${endpoint}:5080/api/v1/applications/${app}/streams/${name}/action/unpublish?accessToken=${api_key}" >/dev/null 2>/dev/null && sleep 0.1

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
    rm -f "$file"
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
        shutdown "${PIDS[${index}]}" "${file}_${i}" "${stream_name}_${i}"
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
    local stream_file=$3
    local name=$4
    local beeN=$5
    
    fail_counter=5
    success=0
    regex_fail="Output #0, rtsp, to"
    
    for ((t=1;t<=fail_counter;t++)); do
        
        while read -r line
        do
            if [[ $line =~ $regex_fail ]]; then
                success=1
            fi
        done < "log/rtspbee_${beeN}.log"
        
        if [ $success -eq 1 ]; then
            log_s "Bee #$beeN --- Deployed. Will kill in ${timeout} seconds, PID:${pid}"
            sleep "$timeout"
            shutdown "$pid" "$stream_file" "$name"
            break
        else
            if [ $t -eq $fail_counter ]; then
                log_w "Bee #$beeN --- Not deployed. Please check log file log/rtspbee_${beeN}.log and target Red5 pro server!!!"
                sleep $((timeout-fail_counter))
                shutdown "$pid" "$stream_file" "$name"
            fi
            sleep 1
        fi
    done
}

printf '%*s\n' "${COLUMNS:-$(tput cols)}" '' | tr ' ' -
log_i "Red5 Pro target server: $endpoint"
log_i "Stream name: $stream_name"
log_i "Amount of bees $amount"
log_i "Time to live bees: $timeout"
log_i "Video file: $file"
printf '%*s\n' "${COLUMNS:-$(tput cols)}" '' | tr ' ' -

trap 'interrupt' SIGINT

# Dispatch.
for ((i=1;i<=amount;i++)); do
    rm -rf ./log/rtspbee_${i}.log
    name="${stream_name}_${i}"
    target="rtsp://${endpoint}:8554/${app}/${name}"
    stream_file="${file}_${i}"
    cp "$file" "$stream_file"
    log_s "Bee #$i --- Deploying... Target: ${target}"
    ffmpeg -re -stream_loop -1 -fflags +igndts -i "${stream_file}" -pix_fmt yuv420p -vsync 1 -threads 0 -vcodec copy -acodec aac -muxdelay 0.0 -rtsp_transport tcp -t "${timeout}" -f rtsp "$target" 3>&1 1>"log/rtspbee_${i}.log" 2>&1 &
    pid=$!
    PIDS+=("${pid}")
    sleep 1
    if [ "$i" -eq "$amount" ]; then
        (checkStatus "$pid" "$timeout" "$stream_file" "$name" "$i")
    else
        (checkStatus "$pid" "$timeout" "$stream_file" "$name" "$i")&
    fi
    sleep 0.2
done

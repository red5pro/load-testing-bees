#!/bin/bash
#===================================================================================
#
# FILE: rtspbee-publisher.sh
#
# USAGE: rtspbee-publisher.sh [endpoint] [app] [streamName] [amount_of_streams_to_start] [amount_of_time_to_playback] [Red5pro_server_API_key] [mp4-file]
#
# EXAMPLE: ./rtspbee-publisher.sh red5pro.server.com 8554 live stream1 10 10 abc123 /path_to_video_file/bbb_480p.mp4
# LOCAL EXAMPLE: ./rtspbee-publisher.sh localhost 8554 live stream1 10 10 abc123 /path_to_video_file/bbb_480p.mp4
#
# DESCRIPTION: Creates N-number of RTSP broadcast with file as a live stream.
# Console output sent to log/rtspbee_streamname_N.log and monitored for status.
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
port=$2
app=$3
stream_name=$4
amount=$5
timeout=$6
api_key=$7
file=$8

dir="./log/rtsp_pub"
amount_of_directories=$( (find ${dir}_* -maxdepth 1 -type d 2>/dev/null | wc -l) )
current_run_number=$((amount_of_directories+1))
current_dir="${dir}_${current_run_number}"
mkdir -p "${current_dir}"
log_file="${current_dir}/rtsp_pub"
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

if [[ -z "$endpoint" || -z "$port" || -z "$app" || -z "$stream_name" || -z "$amount" || -z "$timeout" || -z "$api_key" || -z "$file" ]]; then
    log_w "Not all arguments are set. Please check your command."
    log_w "Example: ./rtspbee-publisher.sh your.red5pro-deploy.com 8554 live stream1 10 10 abc123 /path_to_the_video_file/test.mp4"
    exit 1
fi

if [ ! -f "$file" ]; then
        log_w "File $file does not exist"
        exit 1
fi

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
        shutdown "${PIDS[${index}]}" "${file}_${stream_name}_${i}" "${stream_name}_${i}"
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
    regex_fail="Output #0, rtsp, to"
    
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
                log_w "Bee #$beeN --- Not deployed. Please check log file ${log_file}_${name}.log and target Red5 pro server!!!"
                shutdown "$pid" "$file" "$name"
            fi
            sleep 1
        fi
    done
}

echo "--------------------------------------------------" >> ${log_file}_main.log
printf '%*s\n' "${COLUMNS:-$(tput cols)}" '' | tr ' ' -
log_i "RTSP Publish bees"
log_i "Red5 Pro target server: $endpoint"
log_i "Red5 Pro target port: $port"
log_i "Stream name: $stream_name"
log_i "Amount of bees $amount"
log_i "Time to live bees: $timeout"
log_i "Source file: $file"
printf '%*s\n' "${COLUMNS:-$(tput cols)}" '' | tr ' ' -
echo "--------------------------------------------------" >> ${log_file}_main.log

trap 'interrupt' SIGINT SIGTERM

# Dispatch.
for ((i=1;i<=amount;i++)); do
    name="${stream_name}_rtsp_${current_run_number}_${i}"
    rm -rf "${log_file}_${name}.log"
    target="rtsp://${endpoint}:${port}/${app}/${name}"
    
    log_s "Bee #$i --- Deploying... Target: ${target}"
    log_s "Bee #$i --- Log file: ${log_file}_${name}.log"
    ffmpeg -re -stream_loop -1 -fflags +igndts -i "${file}" -pix_fmt yuv420p -vsync 1 -vcodec copy -acodec aac -muxdelay 0.0 -rtsp_transport tcp -t "${timeout}" -f rtsp "$target" 3>&1 1>"${log_file}_${name}.log" 2>&1 &
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
#!/bin/bash
#===================================================================================
#
# FILE: rtmpbee-publisher.sh
#
# USAGE: rtmpbee-publisher.sh [endpoint] [app] [streamName] [amoun_of_streams_to_start] [amount_of_time_to_playback_in_seconds] [Red5pro_server_API_key] [mp4-file] 
#
# EXAMPLE FOR VIDEO FILE: ./rtmpbee-publisher.sh red5pro.server.com 1935 live stream1 1 60 abc123 /path_to_video_file/bbb_480p.mp4 false
# EXAMPLE FOR AUDIO FILE: ./rtmpbee-publisher.sh red5pro.server.com 1935 live stream1 1 60 abc123 /path_to_audio_file/audio.wav true
# 
# LOCAL EXAMPLE: ./rtmpbee-publisher.sh localhost live stream1 10 100 abc123 /path_to_video_file/bbb_480p.mp4 false       #This will publish 10 Streams for 100 seconds with audio
#
# DESCRIPTION: Creates N-number of RTMP broadcast with file as a live stream.
# Console output sent to log/rtmpbee_streamname_N.log and monitored for status.
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
audio_only=$9

dir="./log/rtmp_pub"
amount_of_directories=$( (find ${dir}_* -maxdepth 1 -type d 2>/dev/null | wc -l) )
current_run_number=$((amount_of_directories+1))
current_dir="${dir}_${current_run_number}"
mkdir -p "${current_dir}"
log_file="${current_dir}/rtmp_pub"
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

if [[ -z "$endpoint" || -z "$port" || -z "$app" || -z "$stream_name" || -z "$amount" || -z "$timeout" || -z "$api_key" || -z "$file" || -z "$audio_only" ]]; then
    log_w "Not all arguments are set. Please check your command."
    log_w "USAGE: ./rtmpbee-publisher.sh [endpoint] [rtmp_port] [app] [streamName] [amoun_of_streams_to_start] [amount_of_time_to_playback_in_seconds] [mp4-file] [boolean_for_audio_only]"
    log_w "Example: ./rtmpbee-publisher.sh your.red5pro-deploy.com 1935 live stream1 10 100 abc123 /path_to_video_file/bbb_480p.mp4 false"
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
    regex_fail="Output #0, flv, to"
    
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
log_i "RTMP Publish bees"
log_i "Red5 Pro target server: $endpoint"
log_i "Red5 Pro target port: $port"
log_i "Stream prefix name: $stream_name"
log_i "Amount of publisher: $amount"
log_i "Time to live publisher: $timeout"
log_i "Video file: $file"
log_i "Audio only enable: $audio_only"
printf '%*s\n' "${COLUMNS:-$(tput cols)}" '' | tr ' ' -
echo "--------------------------------------------------" >> ${log_file}_main.log

trap 'interrupt' SIGINT SIGTERM

for ((i=1;i<=amount;i++)); do
    name="${stream_name}_rtmp_${current_run_number}_${i}"
    rm -rf "${log_file}_${name}.log"
    target="rtmp://${endpoint}:${port}/${app}/${name}"
    
    log_s "Bee #$i --- Deploying... Target: ${target}"
    log_s "Bee #$i --- Log file: ${log_file}_${name}.log"
    if [ "$audio_only" = true ]; then
        ffmpeg -re -stream_loop -1 -fflags +genpts -i "${file}" -acodec aac -ab 128000 -ar 48000 -ac 2 -t "${timeout}" -f flv "$target" 3>&1 1>"${log_file}_${name}.log" 2>&1 &
    else
        ffmpeg -re -stream_loop -1 -fflags +igndts -i "${file}" -pix_fmt yuv420p -vsync 1 -vcodec copy -acodec aac -muxdelay 0.0 -t "${timeout}" -f flv "$target" 3>&1 1>"${log_file}_${name}.log" 2>&1 &
    fi

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

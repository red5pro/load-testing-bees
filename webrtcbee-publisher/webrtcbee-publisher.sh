#!/bin/bash
#===================================================================================
#
# FILE: webrtcbee-publisher.sh
#
# USAGE: webrtcbee-publisher.sh [*publisher.html_endpoint_with_params] [stream_name] [amount_of_streams_to_start] [amount_of_time_to_playback_in_seconds] [path_to_the_video_file.y4m] [path_to_the_audio_file.wav]
#
# For STANDALONE Server Setup
# EXAMPLE FOR VIDEO+AUDIO:  ./webrtcbee-publisher.sh "https://your.red5pro-deploy.com/live/basic-publisher.html?vw=1280&vh=720&fr=30&bwV=1500&bwA=56&audio=1&video=1" stream1 10 60 /path_to_the_video_file/test.y4m /path_to_the_audio_file/test.wav
# EXAMPLE FOR AUDIO ONLY:  ./webrtcbee-publisher.sh "https://your.red5pro-deploy.com/live/basic-publisher.html?vw=1280&vh=720&fr=30&bwV=1500&bwA=56&audio=1&video=0" stream1 10 60 null /path_to_the_audio_file/test.wav
#
# For STREAM_MANAGER Server setup
# EXAMPLE FOR VIDEO+AUDIO:  ./webrtcbee-publisher-sm.sh "https://your.red5pro-deploy.com/red5/proxy-publisher.html?cameraWidth=1280&cameraHeight=720&fr=30&bwV=1500&bwA=56&video=1&audio=1&protocol=wss&port=443&whipwhep=true&verbose=1" stream1 10 60 /path_to_the_video_file/test.y4m /path_to_the_audio_file/test.wav
# EXAMPLE FOR AUDIO ONLY:  ./webrtcbee-publisher-sm.sh "https://your.red5pro-deploy.com/red5/proxy-publisher.html?cameraWidth=1280&cameraHeight=720&fr=30&bwV=1500&bwA=56&video=0&audio=1&protocol=wss&port=443&whipwhep=true&verbose=1" stream1 10 60 null /path_to_the_audio_file/test.wav
#
# DESCRIPTION: Creates N-number of headless WebRTC-based publishers for a live stream.
# Console output sent to log/rtcbee_N.log and monitored for status.
#
# OPTIONS: see function ’usage’ below
# REQUIREMENTS: ---
# BUGS: ---
# NOTES: ---
# AUTHOR: Oles Prykhodko
# COMPANY: Infrared5, Inc.
# VERSION: 2.0.0
#===================================================================================

# For STANDALONE Server setup
# Publish WebRTC stream with video and audio
# ./webrtcbee-publisher.sh "https://your-server.red5.net/live/basic-publisher.html?vw=1920&vh=1080&fr=30&bwV=4500&bwA=56&audio=1&video=1" stream1 1 60 /home/ubuntu/video_examples/240p.y4m /home/ubuntu/video_examples/test_high.wav
# Publish WebRTC stream with audio only
# ./webrtcbee-publisher.sh "https://your-server.red5.net/live/basic-publisher.html?vw=1920&vh=1080&fr=30&bwV=4500&bwA=56&audio=1&video=0" stream1 1 60  null /home/ubuntu/video_examples/test_high.wav


# For STREAM_MANAGER Server setup
# Publish WebRTC stream with video and audio
# ./webrtcbee-publisher.sh "https://your.red5pro-deploy.com/red5/proxy-publisher.html?cameraWidth=1280&cameraHeight=720&fr=30&bwV=1500&bwA=56&video=1&audio=1&protocol=wss&port=443&whipwhep=true&verbose=1" stream1 1 60 /home/ubuntu/video_examples/240p.y4m /home/ubuntu/video_examples/test_high.wav
# Publish WebRTC stream with audio only
# ./webrtcbee-publisher.sh "https://your.red5pro-deploy.com/red5/proxy-publisher.html?cameraWidth=1280&cameraHeight=720&fr=30&bwV=1500&bwA=56&video=0&audio=1&protocol=wss&port=443&whipwhep=true&verbose=1" stream1 1 60  null /home/ubuntu/video_examples/test_high.wav



endpoint=$1
stream_name=$2
amount=$3
timeout=$4 
video_file=$5
audio_file=$6

dir="./log/webrtc_pub"
amount_of_directories=$( (find ${dir}_* -maxdepth 1 -type d 2>/dev/null | wc -l) )
current_run_number=$((amount_of_directories+1))
current_dir="${dir}_${current_run_number}"
mkdir -p "${current_dir}"
log_file="${current_dir}/webrtc_pub"

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

if [[ -z "$stream_name" || -z "$endpoint" || -z "$amount" || -z "$timeout" || -z "$video_file" || -z "$audio_file" ]]; then
    log_w "Not all arguments are set. Please check your command."
    log_w "USAGE: ./webrtcbee-publisher.sh [*publisher.html_endpoint_with_params] [stream_name] [amount_of_streams_to_start] [amount_of_time_to_playback_in_seconds] [path_to_the_video_file.y4m] [path_to_the_audio_file.wav]"
    log_w "Example for Standalone server: ./webrtcbee-publisher.sh 'https://your_server.com/live/basic-publisher.html?vw=1920&vh=1080&fr=30&bwV=4500&bwA=56&audio=1&video=1' stream1 1 60 /home/ubuntu/video_examples/240p.y4m /home/ubuntu/video_examples/test_high.wav"
    log_w "Example for Stream manager server: ./webrtcbee-publisher.sh 'https://your.red5pro-deploy.com/red5/proxy-publisher.html?cameraWidth=1280&cameraHeight=720&fr=30&bwV=1500&bwA=56&video=1&audio=1&protocol=wss&port=443&whipwhep=true&verbose=1' stream1 1 60 /home/ubuntu/video_examples/240p.y4m /home/ubuntu/video_examples/test_high.wav"
    exit 1
fi


#=== FUNCTION ================================================================
# NAME: shutdown
# DESCRIPTION: Shutdown current process
#=============================================================================

function shutdown {
    local pid=$1
    local file=$2

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
    local stream_file=$3
    local name=$4
    local beeN=$5
    
    fail_counter=90
    success=0
    regex_fail="Publish.Start"
    
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
            shutdown "$pid" "$stream_file" "$name"
            break
        else
            if [ $t -eq $fail_counter ]; then
                log_w "Bee #$beeN --- Not deployed. Please check log file ${log_file}_${name}.log and target Red5 pro server!!!"
                shutdown "$pid" "$stream_file" "$name"
            fi
            sleep 1
        fi
    done
}

echo "--------------------------------------------------" >> ${log_file}_main.log
printf '%*s\n' "${COLUMNS:-$(tput cols)}" '' | tr ' ' -
log_i "WebRTC Publish bees"
log_i "Red5 Pro target server: $endpoint"
log_i "Stream prefix name: $stream_name"
log_i "Amount of publisher: $amount"
log_i "Time to live publisher: $timeout"
log_i "Video file: $video_file"
log_i "Audio file: $audio_file"
printf '%*s\n' "${COLUMNS:-$(tput cols)}" '' | tr ' ' -
echo "--------------------------------------------------" >> ${log_file}_main.log

trap 'interrupt' SIGINT SIGTERM

for ((i=1;i<=amount;i++)); do
    name="${stream_name}_webrtc_${current_run_number}_${i}"
    debug_port=$((DEBUG_PORT_START + i))

    if [ -f "${log_file}_${name}.log" ]; then
        rm -rf "${log_file}_${name}.log"
    fi

    endpoint_with_params="${endpoint}&streamName=${name}"
    
    log_s "Bee #$i --- Target: ${endpoint_with_params}"
    log_s "Bee #$i --- Log file: ${log_file}_${name}.log"
    chromium-browser \
    --use-fake-ui-for-media-stream \
    --allow-file-access \
    --use-fake-device-for-media-stream \
    --use-file-for-fake-audio-capture="$audio_file" \
    --use-file-for-fake-video-capture="$video_file" \
    --user-data-dir=/tmp/chrome"$(date +%s%N)" \
    --headless \
    --disable-gpu \
    --mute-audio \
    --window-size=1024,768 \
    --remote-debugging-port="$debug_port" "$endpoint_with_params" 3>&1 1>"${log_file}_${name}.log" 2>&1 &

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

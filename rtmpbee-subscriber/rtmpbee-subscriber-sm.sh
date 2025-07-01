#!/bin/bash
#===================================================================================
#
# FILE: rtmpbee-subscriber-sm.sh
#
# USAGE: rtmpbee-subscriber-sm.sh [endpoint] [SM_username] [SM_password] [Nodegroup_name] [rtmp_port] [app] [streamName] [amount_of_subscribers] [amount_of_time_to_playback_in_seconds]
#
# EXAMPLE: ./rtmpbee-subscriber-sm.sh red5pro.server.com example_user example_password my_nodegroup 1935 live stream1 1 60 
#
# DESCRIPTION: Creates N-number of RTMP subscribers to a given endpoint.
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
sm_username=$2
sm_password=$3
nodegroup_name=$4
port=$5
app=$6
stream_name=$7
amount=$8
timeout=$9

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

if [[ -z "$sm_username" || -z "$sm_password" || -z "$nodegroup_name" || -z "$endpoint" || -z "$port" || -z "$app" || -z "$stream_name" || -z "$amount" || -z "$timeout" ]]; then
    log_w "Not all arguments are set. Please check your command."
    log_w "USAGE: ./rtmpbee-subscriber-sm.sh [endpoint] [SM_username] [SM_password] [Nodegroup_name] [rtmp_port] [app] [streamName] [amount_of_subscribers] [amount_of_time_to_playback_in_seconds] "
    log_w "Example: ./rtmpbee-subscriber-sm.sh your.red5pro-deploy.com example_username example_password your_nodegroup_name 1935 live stream1 10 100"
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
log_i "RTMP Subscribe bees"
log_i "Red5 Stream Manager target server: $endpoint"
log_i "Red5 Stream Manager username: $sm_username"
log_i "Red5 Stream Manager password: $sm_password"
log_i "Red5 Stream Manager nodegroup: $nodegroup_name"
log_i "Red5 Pro node target port: $port"
log_i "Stream prefix name: $stream_name"
log_i "Amount of Subscriber: $amount"
log_i "Time to live bees subscriber: $timeout"
printf '%*s\n' "${COLUMNS:-$(tput cols)}" '' | tr ' ' -
echo "--------------------------------------------------" >> ${log_file}_main.log

trap 'interrupt' SIGINT SIGTERM

create_jwT_token() {
    log_i "Creating JWT token..."
    USER_AND_PASSWORD_IN_BASE64=$(echo -n "$sm_username:$sm_password" | base64)

    for i in {1..5}; do
        JWT_TOKEN_JSON=$(curl -s -X 'PUT' "https://$endpoint/as/v1/auth/login" -H 'accept: application/json' -H "Authorization: Basic $USER_AND_PASSWORD_IN_BASE64")
        JWT_TOKEN=$(jq -r '.token' <<<"$JWT_TOKEN_JSON" 2>/dev/null)

        if [ -z "$JWT_TOKEN" ] || [ "$JWT_TOKEN" == "null" ]; then
            log_w "JWT token was not created! - Attempt $i"
        else
            log_i "JWT token created successfully."
            break
        fi

        if [ "$i" -eq 5 ]; then
            log_e "JWT token was not created!!! EXIT..."
            log_w "JWT_TOKEN_JSON: $JWT_TOKEN_JSON"
            exit 1
        fi
        sleep 5
    done
}

create_jwT_token

for ((i=1;i<=amount;i++)); do
    edge_node=$(curl -s --location --request GET "https:///$endpoint/as/v1/streams/stream/$nodegroup_name/subscribe/live/$stream_name?strict=false&endpoints=1" --header "Authorization: Bearer ${JWT_TOKEN}" --header 'Content-Type: application/json' | jq -r '.[0].serverAddress' 2>/dev/null) 
    
    if [[ -z "$edge_node" ]]; then
        log_w "No Edge node found for subscribing stream: $stream_name."
        exit 1
    fi

    stream_endpoint="rtmp://${edge_node}:${port}/${app}/${stream_name}"
    name="${current_run_number}_${i}"
    rm -rf "${log_file}_${name}.log"
    log_s "Bee #$i --- Deploying... Target: ${stream_endpoint}"
    log_s "Bee #$i --- Log file: ${log_file}_${name}.log"

    ffmpeg -loglevel verbose -i "$stream_endpoint" -t "${timeout}" -f null - 3>&1 1>"${log_file}_${name}.log" 2>&1 &

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

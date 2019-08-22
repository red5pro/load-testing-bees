#!/bin/bash
#===================================================================================
#
# FILE: rtcbee.sh
#
# USAGE: rtcbee.sh [viewer.jsp endpoint] [amount of streams to start] [amount of time to playback]
#
# EXAMPLE: ./rtcbee.sh "https://your.red5pro-deploy.com/live/viewer.jsp?host=your.red5pro-deploy.com&stream=streamname" 10 10
#
# DESCRIPTION: Creates N-number of headless WebRTC-based subscriptions to a live stream.
# Console output sent to log/rtcbee_N.log and monitored for status.
#
# OPTIONS: see function ’usage’ below
# REQUIREMENTS: ---
# BUGS: ---
# NOTES: ---
# AUTHOR: Todd Anderson
# COMPANY: Infrared5, Inc.
# VERSION: 1.1.0

#===================================================================================

DEBUG_PORT_START=9000
endpoint=$1
amount=$2
timeout=$3
pids=()

ulimit -n 65536
ulimit -c unlimited
sysctl fs.inotify.max_user_watches=13166604

process=$(pgrep chromium-browse);

if [ "$process" != "" ]; then
    echo " ---------- Check free ports for start..."
    check_port=$(ls -t ./log/ | head -1 |sed 's/[^0-9]*//g')
    if [ $check_port -gt $DEBUG_PORT_START ];
    then
        DEBUG_PORT_START=$check_port;
    fi
else
    mkdir -p log
    rm -rf ./log/*
    echo " ---------- DELETE OLD LOG FILES"
fi

#=== FUNCTION ================================================================
# NAME: checkStatus
# DESCRIPTION: Check the success or failure status of the bee subscription on stream.
# PARAMETER 1: Index number of the bee to check.
#===============================================================================
function checkStatus {
  bee=$1
  debug_port=$((DEBUG_PORT_START + bee))
  log="log/rtcbee_${debug_port}.log"
  pid=${pids[${bee}-1]}

  echo "Check Status on Bee $bee..."
  failure=0
  success=0
  regex_fail='Subscribe\.(InvalidName|Fail|(Connection\.Closed))'
  regex_success='Subscribe\.Start'

  while read -r line
  do
    if [[ $line =~ $regex_fail ]]; then
      failure=1
    elif [[ $line =~ $regex_success ]]; then
      success=1
    fi
  done < $log

  if [ $failure -eq 1 ]; then       # If failure detected...
    echo "--- ALERT ---"
    echo "Bee $bee failed in its mission. View ${log} for more details."
    kill -9 "$pid" || echo "Failure to kill ${pid}."
    echo "--- // OVER ---"
  elif [[ $success -eq 1 ]]; then   # If success detected...
    echo "--- Success ---"
    echo "Bee $bee has begun attack..."
    (sleep "$timeout"; kill -9 "$pid" || echo "Failure to kill ${pid}.")&
    echo "--- // OVER ---"
  elif ! kill -0 "$pid" 2>/dev/null; then # if pid doesn't exist anymore
    echo "Bee $bee not running pid $pid... terminating"
  else                              # If neither, still in negotiation process.
    echo "no report yet for $bee..."
    (sleep 2; checkStatus "$bee")
  fi
}

# Starting attack...
dt=$(date '+%d/%m/%Y %H:%M:%S')
echo "Starting attack at $dt"

for ((i=1;i<=amount;i++)); do
  debug_port=$((DEBUG_PORT_START + i))
  touch "log/rtcbee_${debug_port}.log"
  chromium-browser --single-process --autoplay-policy=no-user-gesture-required --user-data-dir=/tmp/chrome"$(date +%s%N)" --headless --disable-gpu --mute-audio --window-size=1024,768 --remote-debugging-port=$debug_port "$endpoint" 3>&1 1>"log/rtcbee_${debug_port}.log" 2>&1 &
  pid=$!
  pids[$i-1]=$pid
  echo "Dispatching Bee $i, PID(${pid})..."
  checkStatus $i
  echo "Open port:"$debug_port
  sleep 1
done

dt=$(date '+%d/%m/%Y %H:%M:%S');
echo "Attack deployed at $dt"


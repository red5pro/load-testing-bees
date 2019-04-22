#!/bin/bash

while [ 1 ]; do

TIME=`date '+%H:%M:%S'`
CPU=$(mpstat 1 1 |grep "all" | awk '{ print 100 - $NF; exit; }')
MEM=$(free -m | awk 'NR==2{printf "%.0f\t\t", $3*100/$2 }')
MEMi=$( printf "%.0f" $MEM )
CONNECTIONS=$(cat /usr/local/red5pro/log/red5.log | grep 'counter:' | sed 's/^.*: //' | sed 's/[^0-9]*//g' | tail -1)
echo "|$TIME| |CPU= ${CPU}%| |MEM= ${MEMi}%| |CONNECTIONS= $CONNECTIONS|"
echo "|$TIME| |CPU= ${CPU}%| |MEM= ${MEMi}%| |CONNECTIONS= $CONNECTIONS|" >> cpu_mem_con.log
sleep 5
done

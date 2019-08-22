#!/bin/bash
while [ 1 ]; do

TIME=`date '+%H:%M:%S'`
CPU=$(mpstat 1 1 |grep "all" | awk '{ print 100 - $NF; exit; }')
MEM=$(free -m | awk 'NR==2{printf "%.0f\t\t", $3*100/$2 }')
MEMi=$( printf "%.0f" $MEM )
echo "|$TIME|CPU=${CPU}%|MEM=${MEMi}%|"
sleep 5
done

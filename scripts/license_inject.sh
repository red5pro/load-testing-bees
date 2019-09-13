#!/bin/bash

# = NOTE =
# Use at root of repository: ./scripts/inject-license.sh
RTSPBEE=rtspbee/src/main/java
RTMPBEE=rtmpbee/src/main/java
RTCBEE=rtcbee/src/main/java
STRING="Copyright © 2015 Infrared5"
LICENSE=$(realpath scripts/LICENSE_INJECT)
WAS_UPDATED=0

dirs=( "$RTSPBEE" "$RTMPBEE" "$RTCBEE" )

# check to see if already has license...
for src in "${dirs[@]}"
do
  echo "Traversing ${src}..."
  while IFS= read -r -d '' file; do
        if grep -q "$STRING" "$file"; then
                echo "$file"
                echo "Already has license..."
        else
                cat "$LICENSE" "$file" > $$.tmp && mv $$.tmp "$file"
                WAS_UPDATED=1
        fi
  done < <(find "${src}/" -type f -name "*.java" -print0)
done

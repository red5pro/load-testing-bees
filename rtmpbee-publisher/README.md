# rtmpbee-publisher
RTMP Bee Publisher

# Download BBB
* 480p HD [http://bbb3d.renderfarming.net/download.html](http://bbb3d.renderfarming.net/download.html)

# Convert from AVI to FLV
[Settings Reference](https://www.ezs3.com/public/What_bitrate_should_I_use_when_encoding_my_video_How_do_I_optimize_my_video_for_the_web.cfm)

## Using ffmpeg
```sh
$ ffmpeg -i big_buck_bunny_480p_surround-fix.avi -y -ab 56k -ar 44100 -b:a 54k -b:v 750k -r 24 -f flv output.flv
```

# Streaming

## Using ffmpeg
```sh
$ ffmpeg -re -stream_loop -1 -fflags +genpts -i output.flv -c copy -f flv rtmp://10.0.0.10:1935/live/stream1todd
```

# Attacking
The following will deploy 10 RTMP publishers (`0.2` seconds apart) which will broadcast for 30 seconds each. Their stream names will be appended by `_N`, where `N` rerpesents the number in the sequence that they were deployed - e.g., `stream1_0`, `stream1_1`, etc.

The script will also create `N`-number of copies of the FLV file so that each process is working with their own file for broadcast.

## Using rtmpbee-publisher.sh
```sh
$ ./rtmpbee-publisher.sh ipv6west.red5.org live stream1 10 30 bbb_480p.flv
```

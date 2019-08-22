# RTC Bee publisher
TheRTC Bee publisher is a command-line program that runs a publish "attack" on a server. One *RTC Bee* can have N *Bullets* (or stingers) that are fired concurrently.

* [Requirements](#build-requirements)
* [Preparing](#preparing)
* [Attacking](#attacking)

# Requirements

## CLI

For the command-line based scripts, the following is required:

* chromium-browser

### chromium-browser

To install the `chromium-browser`:

```sh
$ apt-get install -y chromium-browser
```

# Preparing

Before start RTC Bee publisher you need to prepare video file `.y4m` and audio file `.wav`.
For example you can use files: `test_240p_256kbps_15fps.y4m` and `test_high.wav`

## Use FFmpeg for prepare video and audio files: 

### Video file:
```
ffmpeg -i ./test.mp4 -pix_fmt yuv420p ./test.y4m
```
### Audio file:
```
ffmpeg -i ./test.mp4 ./test.wav
```


# Attacking

* [Basic Publisher](#basic-publisher)
* [Stream Manager Proxy Publisher](#stream-manager-proxy-publisher)

## Basic Publisher

```sh
$ cd ./rtcbee-publisher
$ rtcbee_publish.sh [basic-publisher.html endpoint] [amount of streams to start] [amount of time to playback] [path to the video file .y4m] [path to the audio file .wav] [parameters of quality]
```

### Options

#### endpoint

The endpoint of the `basic-publisher.html` page to publish to a stream. 
If you have Red5 Pro server version `5.5.0` and lower, you need to copy this file `basic-publisher.html` into the folder `red5pro/webapps/live/` on the server.

#### amount

The amount of bullets (stingers, a.k.a. stream connections) for the bee to have in the attack.

#### timeout

The amount of time to subscribe to stream. _The actual subscription time may differ from this amount. This is really the time lapse of start of subscription until end._

#### video file

Path to the video file `.y4m`

#### audio file

Path to the audio file `.wav`

#### parameters of quality

You can set manual quality parameters for different testing.
Video Width (vw), Video Height (vh), Frame Rate (fr), Bandwidth Audio (bwA), Bandwidth Video (bwV). 
If you dont set this parameters, script will be use default `vw=640&vh=480&fr=24&bwA=56&bwV=750`


#### Example

example 

```sh
./rtcbee_publish.sh https://your.red5pro-deploy.com/live/basic-publisher.html?streamName=streamname 10 10 /path_to_the_video_file/test.y4m /path_to_the_audio_file/test.wav 'vw=640&vh=480&fr=24&bwA=56&bwV=750'
```

## Stream Manager Proxy Publisher

```sh
$ cd ./rtcbee-publisher
$ rtcbee_publish.sh [proxy-publisher.html endpoint] [amount of streams to start] [amount of time to playback] [path to the video file .y4m] [path to the audio file .wav] [parameters of quality]
```

```sh
$ ./rtcbee_publish.sh https://your.red5pro-streammanager.com/live/proxy-publisher.html?streamName=streamname 10 10 /path_to_the_video_file/test.y4m /path_to_the_audio_file/test.wav 'vw=640&vh=480&fr=24&bwA=56&bwV=750'
#
```


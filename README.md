# LOAD TESTING RED5PRO SERVER AND STREAM MANAGER2.0

## INTRODUCTION

These load test bees script help us to execute Publishing/Subscribing using different protocols for Red5 Pro Standalone and Stream manager2.0 servers.

## REQUIREMENTS

Load tests with Bees use a lot of resources, better to use AWS large instances, such as: `c5.9xlarge` or `c5.18xlarge`. Prepare the server by installing below dependencies to execute these load test scripts.

Store the video and audio file on the server which will be utilized for publishing.

- Install **jq** (Linux or Mac OS only)
  - Linux: `apt install jq`
  - MacOS: `brew install jq`

- Install **ffmpeg** (Linux or Mac OS only)
  - Linux: `apt install ffmpeg`
  - MacOS: `brew install ffmpeg`

- Install **chromium-browser** (Linux or Mac OS only)
  - Linux: `apt install chromium-browser`
  - MacOS: `brew install --cask chromium`

### SUBSCRIBE BEES

* **[RTMP Bees](rtmpbee-subscriber)**  
    #### For Red5 Pro Standalone server
    - USAGE: rtmpbee-subscriber.sh [endpoint] [amount_of_subscribers] [amount_of_time_to_playback_in_seconds]
        ```bash
        
        bash ./rtmpbee-subscriber.sh "rtmp://[your.red5pro-deploy.com]:1935/live/[your_stream_name]" 1 60
        ```
    #### For Stream Manager2.0
    - USAGE: rtmpbee-subscriber-sm.sh [endpoint] [Nodegroup_name] [rtmp_port] [app] [streamName] [amount_of_subscribers] [amount_of_time_to_playback_in_seconds]
        ```bash
        bash ./rtmpbee-subscriber-sm.sh red5pro.server.com your_nodegroup 1935 live stream1 1 60 
    ```
* **[RTSP Bees](rtspbee-subscriber)** 
    #### For Red5 Pro Standalone server
    - USAGE: rtspbee-subscriber.sh [endpoint] [amount_of_subscribers] [amount_of_time_to_playback_stream_in_seconds]
        ```bash
        
        bash ./rtspbee-subscriber.sh "rtsp://[your.red5pro-deploy.com]:8554/live/[your_stream_name]" 1 60
        ```
    #### For Stream Manager2.0
    - USAGE: rtspbee-subscriber-sm.sh [endpoint] [Nodegroup_name] [rtsp_port] [app] [streamName] [amount_of_subscribers] [amount_of_time_to_playback]
        ```bash
        bash ./rtspbee-subscriber-sm.sh your.red5pro-deploy.com your_nodegroup_name 8554 live stream1 10 100
    ```
* **[WebRTC Bees](webrtcbee-subscriber)**
    #### For Red5 Pro Standalone server
    - USAGE: webrtcbee-subscriber.sh [endpoint] [amount_of_subscribers] [amount_of_time_to_playback_stream_in_seconds]
        ```bash
        
        bash ./webrtcbee-subscriber.sh "https://your.server.com/live/viewer.jsp?host=your.server.com&stream=your_stream_name" standalone stream1 1 60
        ```
    #### For Stream Manager2.0
    - USAGE: webrtcbee-subscriber.sh [endpoint] [amount_of_subscribers] [amount_of_time_to_playback_stream_in_seconds]
        ```bash
        bash ./webrtcbee-subscriber.sh "https://your.server.com/red5/proxy-subscriber.html?host=your.server.com&protocol=wss&port=443&whipwhep=true&verbose=1&streamName=your_stream_name" 1 60
    ```

### PUBLISH BEES

* **[RTMP Bees](rtmpbee-publisher)** 
    #### For Red5 Pro Standalone server
    - USAGE: rtmpbee-publisher.sh [endpoint] [rtmp_port] [app] [streamName] [amoun_of_streams_to_start] [amount_of_time_to_playback_in_seconds] [mp4-file] [boolean_for_audio_only]
        ```bash
        bash ./rtmpbee-publisher.sh your.red5pro-deploy.com 1935 live stream1 10 100 abc123 ./path_to_video_file/bbb_480p.mp4 false
        ```
    #### For Stream Manager2.0
    - USAGE: rtmpbee-publisher-sm.sh [endpoint] [Nodegroup_name] [rtmp_port] [app] [streamName] [amoun_of_streams_to_start] [amount_of_time_to_playback_in_seconds] [mp4-file] [boolean_for_audio_only]
        ```bash
        bash ./rtmpbee-publisher-sm.sh your.red5pro-deploy.com your_nodegroup_name 1935 live stream1 10 10 /path_to_video_file/bbb_480p.mp4 false
    ```
* **[RTSP Bees](rtspbee-publisher)** 
    #### For Red5 Pro Standalone server
    - USAGE: rtspbee-publisher.sh [endpoint] [rtsp_port] [app] [streamName] [amoun_of_streams_to_start] [amount_of_time_to_playback_in_seconds] [mp4-file]
        ```bash
        bash ./rtspbee-publisher.sh your.red5pro-deploy.com 8554 live stream1 10 10 abc123 /path_to_the_video_file/test.mp4
        ```
    #### For Stream Manager2.0
    - USAGE: rtspbee-publisher-sm.sh [endpoint] [Nodegroup_name] [rtsp_port] [app] [streamName] [amoun_of_streams_to_start] [amount_of_time_to_playback_in_seconds] [mp4-file]
        ```bash
        bash ./rtspbee-publisher-sm.sh your.red5pro-deploy.com your_nodegroup_name 8554 live stream1 10 10 /path_to_video_file/bbb_480p.mp4
    ```
* **[WebRTC Bees](webrtcbee-publisher)** 
    #### For Red5 Pro Standalone server
    - USAGE: webrtcbee-publisher.sh [*publisher.html_endpoint_with_params] [stream_name] [amount_of_streams_to_start] [amount_of_time_to_playback_in_seconds] [path_to_the_video_file.y4m] [path_to_the_audio_file.wav]
        ```bash
        bash ./webrtcbee-publisher.sh 'https://your_server.com/live/basic-publisher.html?vw=1920&vh=1080&fr=30&bwV=4500&bwA=56&audio=1&video=1' stream1 1 60 /home/ubuntu/video_examples/240p.y4m /home/ubuntu/video_examples/test_high.wav
        ```
    #### For Stream Manager2.0
    - USAGE: webrtcbee-publisher.sh [*publisher.html_endpoint_with_params] [stream_name] [amount_of_streams_to_start] [amount_of_time_to_playback_in_seconds] [path_to_the_video_file.y4m] [path_to_the_audio_file.wav]
        ```bash
        bash ./webrtcbee-publisher.sh 'https://your.red5pro-deploy.com/red5/proxy-publisher.html?cameraWidth=1280&cameraHeight=720&fr=30&bwV=1500&bwA=56&video=1&audio=1&protocol=wss&port=443&whipwhep=true&verbose=1' stream1 1 60 /home/ubuntu/video_examples/240p.y4m /home/ubuntu/video_examples/test_high.wav
    ```
    
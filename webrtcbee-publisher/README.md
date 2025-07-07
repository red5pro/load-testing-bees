## **WebRTC Publisher Bees** 

WebRTC protocol based publishing for Red5 Pro Standalone and Stream manager2.0 servers.

### REQUIREMENTS

Server uses a lot of resources, better to use AWS large instances, such as: `c5.9xlarge` or `c5.18xlarge`. Prepare the server by installing below dependencies to execute these load test scripts.

Store the video and audio file on the server which will be utilized for publishing.

- Install **jq** (Linux or Mac OS only)
  - Linux: `apt install jq`
  - MacOS: `brew install jq`

- Install **chromium-browser** (Linux or Mac OS only)
  - Linux: `apt install chromium-browser`
  - MacOS: `brew install --cask chromium`

### Prepairing Audio and Video files
  - Video file:
    ```
    ffmpeg -i ./your_input_video.mp4 -pix_fmt yuv420p ./output_video_file.y4m
    ```
  - Audio file:
    ```
    ffmpeg -i ./your_input_video.mp4 ./output_audio_file.wav
    ```

### For Red5 Pro Standalone server
- USAGE: webrtcbee-publisher.sh [*publisher.html_endpoint_with_params] [stream_name] [amount_of_streams_to_start] [amount_of_time_to_playback_in_seconds] [path_to_the_video_file.y4m] [path_to_the_audio_file.wav]
    ```bash
    bash ./webrtcbee-publisher.sh 'https://your_server.com/live/basic-publisher.html?vw=1920&vh=1080&fr=30&bwV=4500&bwA=56&audio=1&video=1' stream1 1 60 /home/ubuntu/video_examples/240p.y4m /home/ubuntu/video_examples/test_high.wav
    ```
### For Stream Manager2.0
- USAGE: webrtcbee-publisher.sh [*publisher.html_endpoint_with_params] [stream_name] [amount_of_streams_to_start] [amount_of_time_to_playback_in_seconds] [path_to_the_video_file.y4m] [path_to_the_audio_file.wav]
    ```bash
    bash ./webrtcbee-publisher.sh 'https://your.red5pro-deploy.com/red5/proxy-publisher.html?cameraWidth=1280&cameraHeight=720&fr=30&bwV=1500&bwA=56&video=1&audio=1&protocol=wss&port=443&whipwhep=true&verbose=1' stream1 1 60 /home/ubuntu/video_examples/240p.y4m /home/ubuntu/video_examples/test_high.wav
    ```

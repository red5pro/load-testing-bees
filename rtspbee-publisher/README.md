## **RTSP Publisher Bees**

RTSP protocol based publishing for Red5 Pro Standalone and Stream manager2.0 servers.

### REQUIREMENTS

Scripts uses a lot of resources, better to use AWS large instances, such as: `c5.9xlarge` or `c5.18xlarge`. Prepare the server by installing below dependencies to execute these load test scripts.

Store the video file on the server which will be utilized for publishing.

- Install **jq** (Linux or Mac OS only)
  - Linux: `apt install jq`
  - MacOS: `brew install jq`

- Install **ffmpeg** (Linux or Mac OS only)
  - Linux: `apt install ffmpeg`
  - MacOS: `brew install ffmpeg`

### For Red5 Pro Standalone server
- USAGE: rtspbee-publisher.sh [endpoint] [rtsp_port] [app] [streamName] [amoun_of_streams_to_start] [amount_of_time_to_playback_in_seconds] [mp4-file]
    ```bash
    bash ./rtspbee-publisher.sh your.red5pro-deploy.com 8554 live stream1 10 10 abc123 /path_to_the_video_file/test.mp4
    ```
### For Stream Manager2.0
- USAGE: rtspbee-publisher-sm.sh [endpoint] [Nodegroup_name] [rtsp_port] [app] [streamName] [amoun_of_streams_to_start] [amount_of_time_to_playback_in_seconds] [mp4-file]
    ```bash
    bash ./rtspbee-publisher-sm.sh your.red5pro-deploy.com your_nodegroup_name 8554 live stream1 10 10 /path_to_video_file/bbb_480p.mp4
  ```

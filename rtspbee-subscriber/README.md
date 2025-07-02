## **RTSP Subscriber Bees** 

RTSP protocol based subscribing for Red5 Pro Standalone and Stream manager2.0 servers.

### REQUIREMENTS

Server uses a lot of resources, better to use AWS large instances, such as: `c5.9xlarge` or `c5.18xlarge`. Prepare the server by installing below dependencies to execute these load test scripts.

- Install **jq** (Linux or Mac OS only)
  - Linux: `apt install jq`
  - MacOS: `brew install jq`

- Install **ffmpeg** (Linux or Mac OS only)
  - Linux: `apt install ffmpeg`
  - MacOS: `brew install ffmpeg`

### For Red5 Pro Standalone server
- USAGE: rtspbee-subscriber.sh [endpoint] [amount_of_subscribers] [amount_of_time_to_playback_stream_in_seconds]
    ```bash
    
    bash ./rtspbee-subscriber.sh "rtsp://[your.red5pro-deploy.com]:8554/live/[your_stream_name]" 1 60
    ```
### For Stream Manager2.0
- USAGE: rtspbee-subscriber-sm.sh [endpoint] [Nodegroup_name] [rtsp_port] [app] [streamName] [amount_of_subscribers] [amount_of_time_to_playback]
    ```bash
    bash ./rtspbee-subscriber-sm.sh your.red5pro-deploy.com your_nodegroup_name 8554 live stream1 10 100
    ```

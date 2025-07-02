## **RTMP Subscriber Bees**  

RTMP protocol based subscribing for Red5 Pro Standalone and Stream manager2.0 servers.

### REQUIREMENTS

Scripts uses a lot of resources, better to use AWS large instances, such as: `c5.9xlarge` or `c5.18xlarge`. Prepare the server by installing below dependencies to execute these load test scripts.

- Install **jq** (Linux or Mac OS only)
  - Linux: `apt install jq`
  - MacOS: `brew install jq`

- Install **ffmpeg** (Linux or Mac OS only)
  - Linux: `apt install ffmpeg`
  - MacOS: `brew install ffmpeg`


### For Red5 Pro Standalone server
- USAGE: rtmpbee-subscriber.sh [endpoint] [amount_of_subscribers] [amount_of_time_to_playback_in_seconds]
    ```bash
    bash ./rtmpbee-subscriber.sh "rtmp://[your.red5pro-deploy.com]:1935/live/[your_stream_name]" 1 60
    ```
### For Stream Manager2.0
- USAGE: rtmpbee-subscriber-sm.sh [endpoint] [Nodegroup_name] [rtmp_port] [app] [streamName] [amount_of_subscribers] [amount_of_time_to_playback_in_seconds]
    ```bash
    bash ./rtmpbee-subscriber-sm.sh red5pro.server.com your_nodegroup 1935 live stream1 1 60 
    ```

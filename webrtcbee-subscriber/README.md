## **WebRTC Subscriber Bees**

WebRTC protocol based subscriber for Red5 Pro Standalone and Stream manager2.0 servers.

### REQUIREMENTS

Server uses a lot of resources, better to use AWS large instances, such as: `c5.9xlarge` or `c5.18xlarge`. Prepare the server by installing below dependencies to execute these load test scripts.

- Install **jq** (Linux or Mac OS only)
  - Linux: `apt install jq`
  - MacOS: `brew install jq`

- Install **chromium-browser** (Linux or Mac OS only)
  - Linux: `apt install chromium-browser`
  - MacOS: `brew install --cask chromium`

### For Red5 Pro Standalone server
- USAGE: webrtcbee-subscriber.sh [endpoint] [amount_of_subscribers] [amount_of_time_to_playback_stream_in_seconds]
    ```bash
    
    bash ./webrtcbee-subscriber.sh "https://your.server.com/live/viewer.jsp?host=your.server.com&stream=your_stream_name" standalone stream1 1 60
    ```
### For Stream Manager2.0
- USAGE: webrtcbee-subscriber.sh [endpoint] [amount_of_subscribers] [amount_of_time_to_playback_stream_in_seconds]
    ```bash
    bash ./webrtcbee-subscriber.sh "https://your.server.com/red5/proxy-subscriber.html?host=your.server.com&protocol=wss&port=443&whipwhep=true&verbose=1&streamName=your_stream_name" 1 60
    ```

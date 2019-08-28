# LOAD TESTING RED5PRO SERVER AND STREAM MANAGER

### INTRODUCTION

In this repo present different Bees With Machine Guns for load testing Red5 Pro server and Stream Manager.   
Each Bee program runs an "attack" on a server. It does this by creating clients that subscribe to a video stream coming from that server. One Bee can have a number (N) of Bullets (or stingers, if you will) that are fired concurrently.
By creating these virtual clients, the Bees stress the targeted application server in order to get a better idea of how many concurrent connections the system architecture can support at the same time.

### REQUIREMENTS

Load tests with Bees use a lot of resources, better to use AWS large instances, such as: `c5.9xlarge` or `c5.18xlarge`.   
For start RTMP, RTSP, RTC Subscribe Bees need to publish the stream to Red5pro server with name `stream1`.

#### SUBSCRIBE BEES

* **[RTMP bees](rtmpbee)**  
* **[RTSP bees](rtspbee)**  
* **[WebRTC bees](rtcbee)**

#### PUBLISH BEES

* **[RTMP bees](rtmpbee-publisher)**  
* **[WebRTC bees](rtcbee-publisher)** 

#### AUTOMATED SCRIPT FOR LOAD TESTING

* **[Automated bees](automated-bees)** 


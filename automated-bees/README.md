# Automation for load testing with BEES

## INTRODUCTION
It is shell script for automation start RTMP, RTSP, RTC subscribers bees and RTC publishes bees on the servers or instances and get statistics about CPU load and Memory load.
The script presents a collection of menu-driven options to help for load testing with bees.


## REQUIREMENTS
For load testing with RTMP,RTSP,RTC bees need to create instances with ubuntu 16.04.
Tested with default AWS image: `Ubuntu Server 16.04 LTS (HVM), SSD Volume Type`
Some BEES tests use a lot of resources, better to use large instances, such as: `c5.9xlarge` or `c5.18xlarge`.
For start RTMP,RTSP,RTC SUBSCRIBE BEES you need publish stream to Red5pro server with name `stream1`.

## USAGE

1. `sudo apt install -y git`
2. `git clone https://github.com/red5pro/automated-bees`
3. `cd ./automated-bees`
4. `sudo chmod +x *.sh`
5.  Prepare instances on the AWS for Bees and check ssh access.
6.  Open and modify file `load_test.sh`

```
PEM_FILE="./red5pro.pem"                            # Path on yor computer to .pem file for the ssh access to the BEES servers. EXAMPLE: "./red5pro.pem" 
USER_NAME="ubuntu"                                  # User name on the BEES servers for ssh servers. EXAMPLE: For ubuntu "ubuntu" 
DIRECTORY="/home/ubuntu"                            # Set directory on the Bees server where will be installing bees software. EXAMPLE: For ubuntu "/home/ubuntu" 
DOMAIN="domain_red5pro_server.org"                  # The domain name of Red5pro server or ORIGIN, EDGE for the Load test.
PUBLIC_IPBEES="7.7.7.7, 8.8.8.8, 9.9.9.9"           # IP Address List of BEES servers. EXAMPLE: "7.7.7.7, 8.8.8.8, 9.9.9.9"
```

7. Start `/bin/bash ./red5proInstaller.sh`

Now you are running the `automated-bees` and see `MAIN MENU FOR LOAD TESTING RED5PRO SERVER`
![Main menu](https://github.com/red5pro/automated-bees/blob/master/screen_main_menu.png)

### 1. Install Bees software to Bees servers:

* Press `I` then Enter to start install Bees software for your Bees servers.
* Press `A` then Enter to start install in All you Bees servers.
* Press `X` to exit Main manu.

### 2. Start RTMP, RTSP, RTC load testing.

* Press `1-4` then Enter to open menu for load testing Red5 pro server.
* Press `S` then Enter to start monitoring bees servers `load CPU` and `load Memory`.
* Press `R` then Enter to refresh statisticsh from Bees servers about `load CPU` and `load Memory`.
* Press `1-99` then Enter to start load testing on one Bees server
* Press `A` then Enter to start load testing on the all bees servers.

![Testing menu](https://github.com/red5pro/automated-bees/blob/master/screen_testing_menu.png)

### 3. For monitoring Red5 Pro server you can use script `server_script.sh`

1. Copy this script to Red5pro server: `scp -i key.pem ./server_script.sh ubuntu@red5pro.your.server:/home/ubuntu/`
2. Connect to Red5pro server with ssh: `ssh -i key.pem ubuntu@red5pro.your.server`
3. `sudo chmod +x ./server_script.sh`
4. Start script: `/bin/bash ./server_script.sh`
5. Log file ./cpu_mem_con.log


#### Work `server_script.sh` example:
```
/bin/bash ./server_script.sh
|17:48:43| |CPU= 1%| |MEM= 51%| |CONNECTIONS= 2|
|17:48:49| |CPU= 1%| |MEM= 51%| |CONNECTIONS= 2|
|17:48:55| |CPU= 1%| |MEM= 51%| |CONNECTIONS= 2|
|17:49:01| |CPU= 1%| |MEM= 51%| |CONNECTIONS= 2|
```

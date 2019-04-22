#!/bin/bash
#===================================================================================
# AUTHOR: Oles Prykhodko
# COMPANY: Red5Pro.
# VERSION: 1.0.1
#===================================================================================


PEM_FILE="./red5pro.pem"                            # Path on the yor computer to .pem file for the ssh access to the BEES servers. EXAMPLE: "./red5pro.pem" 

USER_NAME="ubuntu"                                  # User name on the BEES servers for ssh servers. EXAMPLE: For ubuntu "ubuntu" 

DIRECTORY="/home/ubuntu"                            # Set directory on the Bees server where will be installing bees software. EXAMPLE: For ubuntu "/home/ubuntu" 

DOMAIN="domain_red5pro_server.org"                           # The domain name of Red5pro server or ORIGIN, EDGE for the Load test.

PUBLIC_IPBEES="7.7.7.7, 8.8.8.8, 9.9.9.9"           # IP Address List of BEES servers. EXAMPLE: "7.7.7.7, 8.8.8.8, 9.9.9.9"


#################################################################################################################################################################################################
########################################################################### -MAIN MENU ##########################################################################################################
#################################################################################################################################################################################################
cls()
{
    printf "\033c"
}

main(){
    main_menu
    main_menu_options
}

main_menu()
{
    cls
    
    printf '%*s\n' "${COLUMNS:-$(tput cols)}" '' | tr ' ' -
    printf "${WRED} MAIN MENU FOR LOAD TESTING RED5PRO SERVER ${NC}\n"
    printf '%*s\n' "${COLUMNS:-$(tput cols)}" '' | tr ' ' -
    printf "${RED} RED5 PRO server: https://$DOMAIN:443 ${NC}\n"
    printf '%*s\n' "${COLUMNS:-$(tput cols)}" '' | tr ' ' -
    printf "${GREEN} AVAILABLE BEES SERVERS: $BEES_COUNT ${NC}\n"
    printf '%*s\n' "${COLUMNS:-$(tput cols)}" '' | tr ' ' -

    for index in ${!iparray[*]}
    do
            i=$(($index+1))
            printf "${YELLOW} BEES SERVER-${i}: ${iparray[$index]} ${NC}\n"
    done
    printf '%*s\n' "${COLUMNS:-$(tput cols)}" '' | tr ' ' -
    
    echo "                                  "
    echo "I. INSTALL BEES SERVERS           "
    echo "                                  "
    printf '%*s\n' "${COLUMNS:-$(tput cols)}" '' | tr ' ' -
    echo "                                  "
    echo "1. TESTING RTMP SUBSCRIBE BEES    "
    echo "2. TESTING RTSP SUBSCRIBE BEES    "
    echo "3. TESTING RTC SUBSCRIBE BEES 	"
    echo "4. TESTING RTC PUBLISH BEES	    "
    echo "                             		"
    printf '%*s\n' "${COLUMNS:-$(tput cols)}" '' | tr ' ' -
}

main_menu_options()
{
    local choice
    read -p "Enter choice [1 - 4], [I] install, [X] exit " choice
    case $choice in
        [iI]) INSTALL ;;
        1) RTMP ;;
        2) RTSP ;;
        3) RTC ;;
        4) RTCP ;;
        [xX])  exit 0;;
        *) printf "${WRED} Error: Invalid choice ${NC}\n" && sleep 2 && main ;;
    esac
}

#################################################################################################################################################################################################
############################################################################# -ALL MENU #########################################################################################################
#################################################################################################################################################################################################

INSTALL(){
    current_menu="INSTALL"
    name="INSTALL"
    testing_menu
    testing_menu_read_options
}
RTMP(){
    current_menu="RTMP"
    name="RTMP SUBSCRIBE"
    testing_menu
    testing_menu_read_options
}
RTSP(){
    current_menu="RTSP"
    name="RTSP SUBSCRIBE"
    testing_menu
    testing_menu_read_options
}
RTC(){
    current_menu="RTC"
    name="RTC SUBSCRIBE"
    testing_menu
    testing_menu_read_options
}
RTMPP(){
    current_menu="RTMPP"
    name="RTMP PUBLISH"
    testing_menu
    testing_menu_read_options
}
RTCP(){
    current_menu="RTCP"
    name="RTC PUBLISH"
    testing_menu
    testing_menu_read_options
}


testing_menu(){
    cls
    #REFRESH
    printf '%*s\n' "${COLUMNS:-$(tput cols)}" '' | tr ' ' -
    printf "${WGREEN} $name MENU FOR LOAD TESTING RED5PRO SERVER ${NC}\n"
    printf '%*s\n' "${COLUMNS:-$(tput cols)}" '' | tr ' ' -
    printf "${GREEN} AVAILABLE BEES SERVERS: $BEES_COUNT ${NC}\n"
    printf '%*s\n' "${COLUMNS:-$(tput cols)}" '' | tr ' ' -

    for index in ${!iparray[*]}
    do
        i=$(($index+1))
        printf "${YELLOW} BEES SERVER-${i}: ${iparray[$index]} ${NC}\n "
        echo "STATS: ${statarray[$index]} "
        echo "----------------------------------------"
    done

    printf '%*s\n' "${COLUMNS:-$(tput cols)}" '' | tr ' ' -
    echo "                             		"
    
    for index in ${!iparray[*]}
    do
        i=$(($index+1))
        echo "${i}. START $name Bees-${i}   "
    done
    echo "                             		"
    printf '%*s\n' "${COLUMNS:-$(tput cols)}" '' | tr ' ' -
    echo "                             		"
    echo "A. START ALL $name Bees           "
    echo "                             		"
    printf '%*s\n' "${COLUMNS:-$(tput cols)}" '' | tr ' ' -
    echo "                             		"
    echo "S. START MONITORING BEES SERVERS "
    echo "R. REFRESH STATS               	"
    echo "X. MAIN MENU              		"
    echo "                             		"
}

testing_menu_read_options(){

   local choice
    printf '%*s\n' "${COLUMNS:-$(tput cols)}" '' | tr ' ' -
    read -p "|Enter choice [1 - &], [A] ALL, [X] exit| ---> " choice

    case $choice in
        [0-9] | [0-9][0-9]) start_testing_one $choice ;;
        [aA]) start_testing_many ;;
        [sS]) MONITORING;;
        [rR]) REFRESH ;;
        [xX]) main ;;
        *) printf "${WRED} Error: Invalid choice ${NC}\n" && sleep 2 && $current_menu ;;
    esac
}

start_testing_one(){
    if [[ $current_menu != "INSTALL" ]]; then
        read -p "|Enter the number of bees| ---> " number_bees
    fi
    beesserver=$(($1-1));
    case $current_menu in
        INSTALL) install_rtmp_rtsp_rtc_bees ${iparray[beesserver]} ;;
        RTMP) start_rtmp_bees ${iparray[beesserver]} $number_bees $beesserver ;;
        RTSP) start_rtsp_bees ${iparray[beesserver]} $number_bees $beesserver ;;
        RTC) start_rtc_bees ${iparray[beesserver]} $number_bees $beesserver ;;
        RTMPP) start_rtmp_publish_bees ${iparray[beesserver]} $number_bees $beesserver ;;
        RTCP) start_rtc_publish_bees ${iparray[beesserver]} $number_bees $beesserver ;;
    esac
    $current_menu
}

start_testing_many(){
    if [[ $current_menu != "INSTALL" ]]; then
        read -p "|Enter the number of bees| ---> " number_bees
    fi
    for index in ${!iparray[*]}
    do
    case $current_menu in
        INSTALL) install_rtmp_rtsp_rtc_bees ${iparray[$index]} ;;
        RTMP) start_rtmp_bees ${iparray[$index]} $number_bees $index ;;
        RTSP) start_rtsp_bees ${iparray[$index]} $number_bees $index ;;
        RTC) start_rtc_bees ${iparray[$index]} $number_bees $index ;;
        RTMPP) start_rtmp_publish_bees ${iparray[$index]} $number_bees $index ;;
        RTCP) start_rtc_publish_bees ${iparray[$index]} $number_bees $index ;;
    esac
    done
    $current_menu
}


start_rtmp_bees(){
    ssh -o StrictHostKeyChecking=no -i $PEM_FILE $USER_NAME@$1 "java -jar $DIRECTORY/rtmpbee.jar $DOMAIN 1935 live stream1 $2 40000 >/dev/null 2>/dev/null &"
    echo "Start on the server $1, bees: $2"
    sleep 1
}

start_rtsp_bees(){
    ssh -o StrictHostKeyChecking=no -i $PEM_FILE $USER_NAME@$1 "java -jar -noverify $DIRECTORY/rtspbee.jar $DOMAIN 8554 live stream1 $2 20000 >/dev/null 2>/dev/null &"
    echo "Start on the server $1, bees: $2"
    sleep 1
}
start_rtc_bees(){
    ssh -o StrictHostKeyChecking=no -i $PEM_FILE $USER_NAME@$1 "$DIRECTORY/rtcbee/script/rtcbee.sh 'https://$DOMAIN/live/viewer.jsp?host=$DOMAIN&stream=stream1' ' $2' ' 2000' >/dev/null 2>/dev/null &"
    echo "Start on the server $1, bees: $2"
    sleep 1
}
start_rtmp_publish_bees(){
    ssh -o StrictHostKeyChecking=no -i $PEM_FILE $USER_NAME@$1 "$DIRECTORY/rtmpbee-publisher/rtmpbee-publisher.sh '$DOMAIN' 'live' 'stream1' '$2' '6000' '/home/ubuntu/$FILENAME' >/dev/null 2>/dev/null &"    
    echo "Start on the server $1, bees: $2"
    sleep 1
}
start_rtc_publish_bees(){
    ssh -o StrictHostKeyChecking=no -i $PEM_FILE $USER_NAME@$1 "$DIRECTORY/rtcbee/rtcbee-publisher/rtcbee_publish.sh https://$DOMAIN/live/basic-publisher.html?streamName=rtc-test$3 $2 6000 $DIRECTORY/rtcbee/rtcbee-publisher/test_240p_256kbps_15fps.y4m $DIRECTORY/rtcbee/rtcbee-publisher/test_high.wav >/dev/null 2>/dev/null &"
    echo "Start on the server $1, bees: $2 ,index: $3"
    sleep 5
}


install_rtmp_rtsp_rtc_bees(){
scp -o StrictHostKeyChecking=no -i $PEM_FILE ./bees_script.sh $USER_NAME@$1:/$DIRECTORY/bees_script.sh
ssh -o StrictHostKeyChecking=no -i $PEM_FILE $USER_NAME@$1 bash -c "'
export LC_ALL="en_US.UTF-8"
export LC_CTYPE="en_US.UTF-8"
sudo apt-get update
sudo apt-get install -y default-jre
sudo apt-get install -y wget
sudo apt-get install -y unzip
sudo apt-get install -y chromium-browser
sudo apt-get install -y git
sudo apt-get install -y sysstat
cd $DIRECTORY
wget https://github.com/red5pro/rtmpbee/releases/download/4.2.1-release/rtmpbee-4.2.1-RELEASE.zip
unzip rtmpbee-4.2.1-RELEASE.zip 
mv $DIRECTORY/rtmpbee-4.2.1-RELEASE/rtmpbee-4.2.1-RELEASE.jar $DIRECTORY/rtmpbee.jar
rm -r $DIRECTORY/rtmpbee-*
wget https://github.com/red5pro/rtspbee/releases/download/4.2.1-release/rtspbee-4.2.1-RELEASE.zip
unzip rtspbee-4.2.1-RELEASE.zip 
mv $DIRECTORY/rtspbee-4.2.1-RELEASE/rtspbee-4.2.1-RELEASE.jar $DIRECTORY/rtspbee.jar
rm -r $DIRECTORY/rtspbee-*
git clone https://github.com/red5pro/rtcbee.git
chmod +x $DIRECTORY/rtcbee/script/rtcbee.sh $DIRECTORY/rtcbee/rtcbee-publisher/rtcbee_publish.sh $DIRECTORY/bees_script.sh
'"
}


#################################################################################################################################################################################################
############################################################################# --------- #########################################################################################################
#################################################################################################################################################################################################


RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
WRED='\033[0;41m'
WGREEN='\033[0;42m'
WYELLOW='\033[0;43m'
WBLUE='\033[0;44m'
WMAGENTA='\033[0;34m'
WCYAN='\033[0;46m'
NC='\033[0m' # No Color 

check_bees_status(){

    PUBLIC_IPBEESi=$(echo $PUBLIC_IPBEES)
    IFS=', ' read -r -a iparray <<< "$PUBLIC_IPBEESi"
    BEES_COUNT=${#iparray[@]}

        if [ $BEES_COUNT -lt 1 ];
        then
        printf "${RED} AVAILABLE BEES SERVERS: $BEES_COUNT ${NC}\n"
        printf "${RED} Please set ip address of bees servers in the file ./load_test.sh !!! ${NC}\n"
        printf "${RED} Example: PUBLIC_IPBEES=""7.7.7.7, 8.8.8.8, 9.9.9.9"" ${NC}\n"
        exit 0
        fi
}

MONITORING(){
    for index in ${!iparray[*]}
    do

    ssh -o StrictHostKeyChecking=no -i $PEM_FILE $USER_NAME@${iparray[$index]} "$DIRECTORY/bees_script.sh" > bees_${index}.log &
    done
    $current_menu
}

REFRESH(){
    for index in ${!iparray[*]}
    do
        unset ${statarray[$index]}
        local declare test$index=$(tail -n 1 ./bees_${index}.log)
        vartest=test${index}
        statarray[${index}]=${!vartest}
    done
    $current_menu
}


 while [ 1 ];
 do
     check_bees_status
     main
    
 done
#!/bin/sh

#----make sure this is run as root
user=`id -u`
if [ $user -ne 0 ]; then
    echo "This script requires root permissions. Please run this script with sudo."
    exit
fi

#----ascii art!
echo " _           _     _                 _       _                   "
echo "| |         | |   | |               | |     | |                  "
echo "| |__   ___ | |_  | |__   ___   ___ | |_ ___| |_ _ __ __ _ _ __  "
echo "| '_ \ / _ \| __| | '_ \ / _ \ / _ \| __/ __| __| '__/ _\` | '_ \ "
echo "| |_) | (_) | |_  | |_) | (_) | (_) | |_\__ \ |_| | | (_| | |_) |"
echo "|_.__/ \___/ \__| |_.__/ \___/ \___/ \__|___/\__|_|  \__,_| .__/ "
echo "                                                          | |    "
echo "                                                          |_|    "

#----intro message
echo ""
echo "-----------------------------------------------------------------------"
echo "Welcome! Let's set up your Raspberry Pi with the Conversational bot."
echo ""
echo "Enjoy the ride"
echo "-----------------------------------------------------------------------"


#----test raspbian version: if it's older than jessie, it may not work
RASPIAN_VERSION_ID=`cat /etc/os-release | grep VERSION_ID | cut -d '"' -f 2`
RASPIAN_VERSION=`cat /etc/os-release | grep VERSION= | cut -d '"' -f 2`
if [ $RASPIAN_VERSION_ID -lt 8 ]; then
    echo "Warning: it looks like your Raspberry Pi is running an older version"
    echo "of Raspian. TJBot has only been tested on Raspian 8 (Jessie) and"
    echo "later."
    echo ""
    read -p "Would you like to continue with setup? [Y/n] " choice </dev/tty
    case "$choice" in
        "n" | "N")
            echo "OK, TJBot software will not be installed at this time."
            exit
            ;;
        *) ;;
    esac
fi

#----setting DNS to Quad9
echo ""
echo "In some networking environments, using Quad9's nameservers may speed up"
echo "DNS queries and provide extra security and privacy."
echo "Adding Quad9 DNS servers to /etc/resolv.conf"
if ! grep -q "nameserver 9.9.9.9" /etc/resolv.conf; then
    echo "nameserver 9.9.9.9" | tee -a /etc/resolv.conf
    echo "nameserver 149.112.112.112" | tee -a /etc/resolv.conf
fi

#----nodejs install
echo ""
RECOMMENDED_NODE_LEVEL="15"
MIN_NODE_LEVEL="15"
NEED_NODE_INSTALL=false

if which node > /dev/null; then
    NODE_VERSION=$(node --version 2>&1)
    NODE_LEVEL=$(node --version 2>&1 | cut -d '.' -f 1 | cut -d 'v' -f 2)
    if [ $NODE_LEVEL -lt $MIN_NODE_LEVEL ]; then
        echo "Node.js v$NODE_VERSION.x is currently installed. We recommend installing"
        echo "v$MIN_NODE_LEVEL.x or later."
        NEED_NODE_INSTALL=true
    fi
else
    echo "Node.js is not installed."
    NEED_NODE_INSTALL=true
fi

if $NEED_NODE_INSTALL; then
    read -p "Would you like to install Node.js v$RECOMMENDED_NODE_LEVEL.x? [Y/n] " choice </dev/tty
    case "$choice" in
        "" | "y" | "Y")
            curl -sL https://deb.nodesource.com/setup_${RECOMMENDED_NODE_LEVEL}.x | sudo bash -
            apt-get install -y nodejs
            ;;
        *)
            echo "Warning: TJBot may not operate without installing a current version of Node.js."
            ;;
    esac
fi

#----install additional packages
echo ""
if [ $RASPIAN_VERSION_ID -eq 8 ]; then
    echo "Installing additional software packages for Jessie (alsa, libasound2-dev, git, pigpio)"
    apt-get install -y alsa-base alsa-utils libasound2-dev git pigpio
#elif [ $RASPIAN_VERSION -eq 9 ]; then
#    echo "Installing additional software packages for Stretch (libasound2-dev)"
#    apt-get install -y libasound2-dev
fi

#----remove outdated apt packages
echo ""
echo "Removing unused software packages [apt-get autoremove]"
apt-get -y autoremove

#----enable camera on raspbery pi
echo ""
echo "If your Raspberry Pi has a camera installed, TJBot can use it to see."
read -p "Enable camera? [y/N] " choice </dev/tty
case "$choice" in
    "y" | "Y")
        if grep "start_x=1" /boot/config.txt
        then
            echo "Camera is already enabled."
        else
            echo "Enabling camera."
            if grep "start_x=0" /boot/config.txt
            then
                sed -i "s/start_x=0/start_x=1/g" /boot/config.txt
            else
                echo "start_x=1" | tee -a /boot/config.txt >/dev/null 2>&1
            fi
            if grep "gpu_mem=128" /boot/config.txt
            then
                :
            else
                echo "gpu_mem=128" | tee -a /boot/config.txt >/dev/null 2>&1
            fi
        fi
        ;;
    *) ;;
esac

#----clone tjbot
echo ""
echo "We are ready to clone the TJBot project."
TJBOT_DIR='/home/pi/Desktop/tjbot'

if [ ! -d $TJBOT_DIR ]; then
    echo "Cloning TJBot project to $TJBOT_DIR"
    sudo -u $SUDO_USER git clone https://github.com/MrMelendik/conversation-bot-isc.git $TJBOT_DIR
else
    echo "TJBot project already exists in $TJBOT_DIR, leaving it alone"
fi

#----installing nodejs packages
"Changing directory to install packages"
cd Desktop/tjbot/recipes/conversation
"Installing nodejs packages"
npm install
sudo node conversation.js


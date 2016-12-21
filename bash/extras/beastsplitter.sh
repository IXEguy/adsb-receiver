#!/bin/bash

#####################################################################################
#                                  ADS-B RECEIVER                                   #
#####################################################################################
#                                                                                   #
# This script is not meant to be executed directly.                                 #
# Instead execute install.sh to begin the installation process.                     #
#                                                                                   #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#                                                                                   #
# Copyright (c) 2015-2016 Joseph A. Prochazka                                       #
#                                                                                   #
# Permission is hereby granted, free of charge, to any person obtaining a copy      #
# of this software and associated documentation files (the "Software"), to deal     #
# in the Software without restriction, including without limitation the rights      #
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell         #
# copies of the Software, and to permit persons to whom the Software is             #
# furnished to do so, subject to the following conditions:                          #
#                                                                                   #
# The above copyright notice and this permission notice shall be included in all    #
# copies or substantial portions of the Software.                                   #
#                                                                                   #
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR        #
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,          #
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE       #
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER            #
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,     #
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE     #
# SOFTWARE.                                                                         #
#                                                                                   #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

## VAARIABLES

PROJECT_ROOT_DIRECTORY="$PWD"
BASH_DIRECTORY="$PROJECT_ROOT_DIRECTORY/bash"
BUILD_DIRECTORY="$PROJECT_ROOT_DIRECTORY/build"

## INCLUDE EXTERNAL SCRIPTS

source $BASH_DIRECTORY/variables.sh
source $BASH_DIRECTORY/functions.sh

## BEGIN SETUP

clear
echo -e "\n\e[91m  $ADSB_PROJECTTITLE"
echo ""
echo -e "\e[92m  Setting up beast-splitter..."
echo -e "\e[93m----------------------------------------------------------------------------------------------------\e[96m"
echo ""
whiptail --backtitle "$ADSB_PROJECTTITLE" --title "Beast-Splitter Setup" --yesno "This is a helper utility for the Mode-S Beast.\n\nThe Beast provides a single data stream over a (USB) serial port. If you have more than one thing that wants to read that data stream, you need something to redistribute the data. This is what beast-splitter does.\n\n  https://github.com/flightaware/beast-splitter\n\nContinue beast-splitter setup?" 15 78
CONTINUESETUP=$?
if [ $CONTINUESETUP = 1 ]; then
    # Setup has been halted by the user.
    echo -e "\e[91m  \e[5mINSTALLATION HALTED!\e[25m"
    echo -e "  Setup has been halted at the request of the user."
    echo ""
    echo -e "\e[93m----------------------------------------------------------------------------------------------------"
    echo -e "\e[92m  beast-splitter setup halted.\e[39m"
    echo ""
    read -p "Press enter to continue..." CONTINUE
    exit 1
fi

## CHECK FOR PREREQUISITE PACKAGES

# Ask the beast-splitter listen port.
LISTEN_PORT_TITLE="Listen Port"
while [[ -z $LISTEN_PORT ]]; do
    LISTEN_PORT=$(whiptail --backtitle "$ADSB_PROJECTTITLE" --backtitle "$BACKTITLETEXT" --title "$LISTEN_PORT_TITLE" --nocancel --inputbox "\nPlease enter the port beast-splitter will listen on.\nThis must be a port which is currently not in use." 10 78 "30005" 3>&1 1>&2 2>&3)
    LISTEN_PORT_TITLE="Listen Port (REQUIRED)"
done

# Ask the beast-splitter connect port.
CONNECT_PORT_TITLE="Connect Port"
while [[ -z $CONNECT_PORT ]]; do
    CONNECT_PORT=$(whiptail --backtitle "$ADSB_PROJECTTITLE" --backtitle "$BACKTITLETEXT" --title "$CONNECT_PORT_TITLE" --nocancel --inputbox "\nPlease enter the port beast-splitter will connect to.\nThis is generally port 30104 on dump1090." 10 78 "30104" 3>&1 1>&2 2>&3)
    CONNECT_PORT_TITLE="Connect Port (REQUIRED)"
done

echo -e "\e[95m  Installing packages needed to build and fulfill dependencies...\e[97m"
echo ""
CheckPackage build-essential
CheckPackage debhelper
CheckPackage libboost-system-dev
CheckPackage libboost-program-options-dev
CheckPackage libboost-regex-dev
CheckPackage dh-systemd

## DOWNLOAD OR UPDATE THE BEAST-SPLITTER SOURCE

echo ""
echo -e "\e[95m  Preparing the beast-splitter Git repository...\e[97m"
echo ""
if [ -d $BUILD_DIRECTORY/beast-splitter ] && [ -d $BUILD_DIRECTORY/beast-splitter/.git ]; then
    # A directory with a git repository containing the source code already exists.
    echo -e "\e[94m  Entering the beast-splitter git repository directory...\e[97m"
    cd $BUILD_DIRECTORY/beast-splitter
    echo -e "\e[94m  Updating the local beast-splitter git repository...\e[97m"
    echo ""
    git pull
else
    # A directory containing the source code does not exist in the build directory.
    echo -e "\e[94m  Entering the ADS-B Receiver Project build directory...\e[97m"
    cd $BUILD_DIRECTORY
    echo -e "\e[94m  Cloning the beast-splitter git repository locally...\e[97m"
    echo ""
    git clone https://github.com/flightaware/beast-splitter.git
fi

## BUILD AND INSTALL THE BEAST-SPLITTER PACKAGE

echo ""
echo -e "\e[95m  Building and installing the beast-splitter package...\e[97m"
echo ""
if [ ! $PWD = $BUILD_DIRECTORY/beast-splitter ]; then
    echo -e "\e[94m  Entering the piaware_builder git repository directory...\e[97m"
    cd $BUILD_DIRECTORY/beast-splitter
fi
echo -e "\e[94m  Executing the beast-splitter build script...\e[97m"
echo ""
dpkg-buildpackage -b
echo ""
echo -e "\e[94m  Entering the ADS-B Receiver Project build directory...\e[97m"
cd $BUILD_DIRECTORY
echo -e "\e[94m  Installing the beast-splitter package...\e[97m"
sudo dpkg -i beast-splitter_*.deb
if [ -d $BUILD_DIRECTORY/beast-splitter/packages ]; then
    echo -e "\e[94m  Creating a directory within the beast-splitter build directory to store built packages...\e[97m"
    mkdir $BUILD_DIRECTORY/beast-splitter/packages
fi
echo -e "\e[94m  Moving the beast-splitter package into the beast-splitter package directory...\e[97m"
mv $BUILD_DIRECTORY/beast-splitter_*.deb $BUILD_DIRECTORY/beast-splitter/packages/

## CREATE THE SCRIPT TO BE USED TO EXECUTE BEAST-SPLITTER

echo -e "\e[94m  Creating the file beast-splitter_maint.sh...\e[97m"
tee $BUILD_DIRECTORY/beast-splitter/beast-splitter_maint.sh > /dev/null <<EOF
#! /bin/sh
while true
  do
    sleep 30
    beast-splitter --serial /dev/beast --listen $LISTEN_PORT:R --connect localhost:$CONNECT_PORT:R
  done
EOF

echo -e "\e[94m  Setting file permissions for beast-splitter_maint.sh...\e[97m"
sudo chmod +x $BUILD_DIRECTORY/beast-splitter/beast-splitter_maint.sh

echo -e "\e[94m  Checking if the beast-splitter startup line is contained within the file /etc/rc.local...\e[97m"
if ! grep -Fxq "$BUILD_DIRECTORY/beast-splitter/beast-splitter_maint.sh &" /etc/rc.local; then
    echo -e "\e[94m  Adding the beast-splitter startup line to the file /etc/rc.local...\e[97m"
    lnum=($(sed -n '/exit 0/=' /etc/rc.local))
    ((lnum>0)) && sudo sed -i "${lnum[$((${#lnum[@]}-1))]}i $BUILD_DIRECTORY/beast-splitter/beast-splitter_maint.sh &\n" /etc/rc.local
fi

## START BEAST-SPLITTER

echo ""
echo -e "\e[95m  Starting beast-splitter...\e[97m"
echo ""

# Kill any currently running instances of the beast-splitter_maint.sh script.
echo -e "\e[94m  Checking for any running beast-splitter_maint.sh processes...\e[97m"
PIDS=`ps -efww | grep -w "beast-splitter_maint.sh" | awk -vpid=$$ '$2 != pid { print $2 }'`
if [ ! -z "$PIDS" ]; then
    echo -e "\e[94m  Killing any running beast-splitter_maint.sh processes...\e[97m"
    sudo kill $PIDS
    sudo kill -9 $PIDS
fi
# Kill any currently running instances beast-splitter.
echo -e "\e[94m  Checking for any running beast-splitter processes...\e[97m"
PIDS=`ps -efww | grep -w "beast-splitter" | awk -vpid=$$ '$2 != pid { print $2 }'`
if [ ! -z "$PIDS" ]; then
    echo -e "\e[94m  Killing any running beast-splitter processes...\e[97m"
    sudo kill $PIDS
    sudo kill -9 $PIDS
fi

echo -e "\e[94m  Executing the beast-splitter_maint.sh script...\e[97m"
sudo nohup $BUILD_DIRECTORY/beast-splitter/beast-splitter_maint.sh > /dev/null 2>&1 &

## BEAST-SPLITTER SETUP COMPLETE

# Enter into the project root directory.
echo -e "\e[94m  Entering the ADS-B Receiver Project root directory...\e[97m"
cd $PROJECT_ROOT_DIRECTORY

echo ""
echo -e "\e[93m-------------------------------------------------------------------------------------------------------"
echo -e "\e[92m  ADS-B Exchange feed setup is complete.\e[39m"
echo ""
read -p "Press enter to continue..." CONTINUE

exit 0
#!/bin/bash
#####################################################################################################
#
# This is Android FIsH: [F]luffy [I]ncredible [s]teadfasterX [H]ijack
#
# Copyright (C) 2017 steadfasterX <steadfastX@boun.cr>
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Lesser General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Lesser General Public License for more details.
# 
# You should have received a copy of the GNU Lesser General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
#
######################################################################################################

cat <<EOCP

Android FIsH Copyright (C) 2017 steadfasterX <steadfastX@boun.cr>

This program comes with ABSOLUTELY NO WARRANTY!
This is free software, and you are welcome to redistribute it
under certain conditions.

The complete license and copying can be found in the file
COPYING and COPYING.LESSER

EOCP

echo "*********************************************************************"
echo "**   Android FIsH: [F]luffy [I]ncredible [s]teadfasterX [H]ijack   **"
echo "*********************************************************************"


# The full URL to the busybox version compatible to your device:
BUSYBOXURI="https://busybox.net/downloads/binaries/1.26.2-defconfig-multiarch/busybox-armv6l"

# the required android sdk version -> have to match the fish you package 
# (e.g. TWRP have to be compatible with that version)
# This version here means the STOCK ROM version you expect for this package!
# find the correct SDK version e.g. here: https://en.wikipedia.org/wiki/Android_version_history
MINSDK="22"

# minimal required SuperSU version. TRUST me u will encounter problems with >2.79!
# well 2.67 should work but i will not tell anyone ;) (totally untested)
MINSU="279"


##############################################################################################

# we do not want to distribute busybox to avoid licensing issues so u need to download it:
echo -e "\n############# Checking for busybox"
[ ! -f fishing/busybox ] && echo "...downloading busybox" && wget "$BUSYBOXURI" -O fishing/busybox && chmod 755 fishing/busybox
[ ! -f fishing/busybox ] && echo "ERROR: MISSING BUSYBOX! Download it manually and place it in the directory: ./fishing/ and name it <busybox>" && exit 3

# preparing your system
adb start-server
echo -e "Waiting for your device... (you may have to switch to PTP mode on some devices!!)"
adb wait-for-device

# precheck min requirement adb:
adb version
[ $? -ne 0 ]&& echo "ADB is not installed?! Use FWUL (https://tinyurl.com/FWULatXDA) you FOOL! :)" && exit

F_ERR(){
    ERR=${1/*=/}
    [ -z "$ERR" ]&& echo "ERROR IN ERROR HANDLING! $1 was cut down to: $ERR" && exit

    if [ "$ERR" -ne 0 ];then
        echo "--> ERROR!! ABORTED WITH ERROR $ERR! Check the above output!"
        exit 3
    else
        echo "-> command ended successfully ($1)"
    fi
}

echo "############# checking Android version"
AVER=$(adb shell getprop ro.build.version.sdk| tr -d '\r')
if [ "$AVER" -lt "$MINSDK" ];then
    echo -e "\n\n***************************************************************"
    echo "ERROR! You have Android $AVER running but $MINSDK is required. FIsH will not be able to boot! ABORTED."
    echo -e "***************************************************************\n\n"
    exit 3
else
    if [ "$AVER" -gt "$MINSDK" ];then
        echo -e "\n\n***************************************************************"
        echo "ERROR: Your SDK version ($AVER) is HIGHER then $MINSDK"
        echo -e "This check ensures that the FISHFOOD is compatible with the\nramdisk we hijack!"
        echo "You can adjust MINSDK but ensure the FISHFOOD is compatible first!"
        echo "***************************************************************\n\n"
        exit 3
    else
        echo "-> Good. Matching exact the required Android SDK: $MINSDK"
    fi
fi

echo "############# checking SuperSU version"
SUVER=$(adb shell su -v|cut -d ":" -f1 |tr -d '.'| tr -d '\r')
if [ "$SUVER" -ge "$MINSU" ];then
    echo "-> Matching required SuperSU version: $SUVER"
else
    echo "ERROR! You have SuperSU $SUVER running but $MINSU is required. FIsH will not be able to boot! ABORTED."
    echo "Update to at least v${MINSU} with e.g. FlashFire or similar."
    exit 3
fi

echo "############# temporary disable SELinux"
CURSELINUX=$(adb shell getenforce |tr -d '\r')
RET=$(adb shell 'su -c setenforce 0; echo err=$?' | grep err=|tr -d '\r')
F_ERR $RET
SEL="$(adb shell getenforce|tr -d '\r')"
echo "SELinux mode: $SEL"
[ "$SEL" != "Permissive" ]&& echo 'ABORTED!!! YOU CAN NOT GET PERMISSIVE SELINUX MODE!' && exit

# check if we run in testing mode and exit
if [ "$1" == "--check" ];then
    echo "... restoring SELinux mode to $CURSELINUX"
    adb shell "su -c setenforce $CURSELINUX"
    echo -e "\n\nTests finished! Check the above output!! Exiting here because in checking mode. Nothing installed.\n\n"
    exit
fi

echo "############# remount /system"
RET=$(adb shell "su -c 'mount -oremount,rw /system; echo err=$?'" | grep err=|tr -d '\r') # bullshit.. mount do not return a valid errorcode!
#F_ERR $RET
echo "############# cleaning"
RET=$(adb shell 'su -c rm -Rf /data/local/tmpfish/; echo err=$?' | grep err= |tr -d '\r')
F_ERR $RET
RET=$(adb shell 'su -c rm -f /system/su.d/FIsH; echo err=$?' | grep err= |tr -d '\r')
F_ERR $RET
RET=$(adb shell 'su -c rm -f /system/su.d/callmeFIsH; echo err=$?' | grep err= |tr -d '\r')
F_ERR $RET
RET=$(adb shell 'su -c rm -Rf /system/fish; echo err=$?' | grep err= |tr -d '\r')
F_ERR $RET
echo "############# creating temporary directory"
RET=$(adb shell 'su -c mkdir /data/local/tmpfish; echo err=$?' | grep err=|tr -d '\r')
F_ERR $RET
RET=$(adb shell 'su -c chmod 777 /data/local/tmpfish; echo err=$?' | grep err=|tr -d '\r')
F_ERR $RET
echo "############# pushing files"
for fishes in $(find fishing/ -type f );do adb push $fishes /data/local/tmpfish/;done
RET=$(adb shell 'su -c chmod 755 /data/local/tmpfish/gofishing.sh; echo err=$?' | grep err=|tr -d '\r')
F_ERR $RET
echo "############# injecting the FIsH"
RET=$(adb shell 'su -c /data/local/tmpfish/gofishing.sh; echo err=$?' | grep err=|tr -d '\r')
F_ERR $RET
echo "############# remount /system RO again"
RET=$(adb shell 'su -c mount -oremount,ro /system; echo err=$?' | grep err=|tr -d '\r') # bullshit.. mount do not return a valid errorcode!
#F_ERR $RET
echo "############# restoring SELinux mode to $CURSELINUX"
RET=$(adb shell "su -c setenforce $CURSELINUX; echo err=$?" | grep err= |tr -d '\r')
F_ERR $RET
echo "ALL DONE! Reboot and enjoy the FIsH."
echo
echo -e "Get support on IRC:\n"
echo -e "\tInstall HexChat (https://hexchat.github.io) -> channel #Carbon-user on freenode"
echo -e "\tor"
echo -e "\tjust open http://webchat.freenode.net/?channels=Carbon-user"
echo 
echo

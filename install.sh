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


*********************************************************************
**   Android FIsH: [F]luffy [I]ncredible [s]teadfasterX [H]ijack   **
*********************************************************************

EOCP

# The full URL to the busybox version compatible to your device:
BUSYBOXURI="https://busybox.net/downloads/binaries/1.26.2-defconfig-multiarch/busybox-armv6l"

# the required android sdk version -> have to match the fishfood you are about to package 
# (e.g. TWRP have to be compatible with that version)
# This version here means the minimum(!) STOCK ROM version you expect for this package!
# find the correct SDK version e.g. here: https://en.wikipedia.org/wiki/Android_version_history
MINSDK="22"

# minimal required SuperSU version. TRUST me u will encounter problems with >2.79!
# well 2.67 should work but i will not tell anyone ;) (totally untested)
MINSU="279"

##### Check to see if this script is running on Android or PC #####

if [ -f /system/build.prop ];then
        echo "Installer is running on Android"
        device="Android"
else
        echo "Installer is running on PC"
        device="PC"
fi

##############################################################################################

# check if there is --check ANYWHERE on the parameter list to be 100% sure that no bad things happen when unwanted
echo "$@" | grep "check" >> /dev/null
if [ $? -eq 0 ];then
    CHKMODE=yes
    echo "Installer is running in CHECK-ONLY mode!"
else
    CHKMODE=no
    echo "Installer is running in REAL-INSTALLATION mode!"
fi

# we do not want to distribute busybox to avoid licensing issues so u need to download it (wget cmd may missing when running on Android..):
echo -e "\n############# Checking for busybox"
[ ! -f fishing/busybox ] && echo "...downloading busybox" && wget "$BUSYBOXURI" -O fishing/busybox && chmod 755 fishing/busybox
[ ! -f fishing/busybox ] && echo "ERROR: MISSING BUSYBOX! Download it manually and place it in the directory: ./fishing/ and name it <busybox>" && exit 3

# preparing your system
if [ $device == "PC" ];then
    adb start-server
    echo -e "Waiting for your device... (you may have to switch to PTP mode on some devices!!)"
    adb wait-for-device
fi

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
REQSDK=nok

if [ $device == "Android" ];then
	AVER=$(getprop ro.build.version.sdk| tr -d '\r')
else
    AVER=$(adb shell getprop ro.build.version.sdk| tr -d '\r')
fi

if [ "$CHKMODE" == "yes" ];then
    echo -e "You have Android SDK ${AVER} running on your device"
    REQSDK=checkmode_yourSDK_is_${AVER}
else
    if [ "$AVER" -lt "$MINSDK" ];then
        echo -e "\n\n***************************************************************"
        echo -e "You have Android $AVER running but $MINSDK is set to required by the FIsH dev.\nFIsH might not be able to boot!"
        echo
        echo -e "This check ensures that the FIsHFOOD is 100% compatible with the ramdisk we hijack"
        echo -e "and it seems that this is not the case or the dev just had forgotten to change the MINSDK :p"
        echo -e "You can adjust MINSDK on your own in this script but ensure the FISHFOOD is compatible first!"
        echo -e "***************************************************************\n\n"
        exit 3
    else
        if [ "$AVER" -gt "$MINSDK" ];then
            echo -e "\n\n***************************************************************"
            echo -e "Your SDK version ($AVER) is HIGHER then $MINSDK\nFIsH might not be able to boot!"
            echo 
            echo -e "This check ensures that the FIsHFOOD is 100% compatible with the ramdisk we hijack"
            echo -e "and it seems that this is not the case or the dev just had forgotten to change the MINSDK :p"
            echo -e "You can adjust MINSDK on your own in this script but ensure the FISHFOOD is compatible first!"
            echo -e "***************************************************************\n\n"
            exit 3
        else
            echo "-> Good. Matching exact the required Android SDK: $MINSDK"
            REQSDK=ok
        fi
    fi
fi

echo "############# checking SuperSU version"
REQSU=notok

if [ $device == "Android" ];then
    SUVER=$(su -v|cut -d ":" -f1 |tr -d '.'| tr -d '\r')
else
    SUVER=$(adb shell su -v|cut -d ":" -f1 |tr -d '.'| tr -d '\r')
fi

if [ "$SUVER" -ge "$MINSU" ];then
    echo "-> Matching required SuperSU version: $SUVER"
    REQSU=ok
else
    echo "ERROR! You have SuperSU $SUVER running but $MINSU is required. FIsH will not be able to boot!"
    echo "Update to at least v${MINSU} with e.g. FlashFire or similar."
    if [ "$CHKMODE" == "yes" ];then REQSU=notok; else exit 3; fi
fi

echo "############# temporary disable SELinux"
if [ $device == "Android" ];then
	CURSELINUX=$(getenforce |tr -d '\r')
	RET=$(su -c setenforce 0; echo err=$? | grep err=|tr -d '\r')
	F_ERR $RET
	SEL="$(getenforce|tr -d '\r')"
	echo "SELinux mode: $SEL"
        if [ "$SEL" != "Permissive" ];then
            echo -e 'YOU CAN NOT GET PERMISSIVE SELINUX MODE! Do you really have a FULL rooted device? It seems not..\nTry this in an adb shell: "su -c setenforce permissive"'
            if [ "$CHKMODE" == "yes" ];then 
                REQSEL=notok
            else
        	exit 3
            fi
        else
            REQSEL=ok
        fi
else
    CURSELINUX=$(adb shell getenforce |tr -d '\r')
    RET=$(adb shell 'su -c setenforce 0; echo err=$?' | grep err=|tr -d '\r')
    F_ERR $RET
    SEL="$(adb shell getenforce|tr -d '\r')"
    echo "SELinux mode: $SEL"
    if [ "$SEL" != "Permissive" ];then
        echo -e 'YOU CAN NOT GET PERMISSIVE SELINUX MODE! Do you really have a FULL rooted device? It seems not..\nTry this in an adb shell: "su -c setenforce permissive"'
        if [ "$CHKMODE" == "yes" ];then
            REQSEL=notok
        else
            exit 3
        fi
    else
        REQSEL=ok
    fi    
fi

# if we run in testing mode revert things and exit here
if [ "$CHKMODE" == "yes" ];then
    echo "... restoring SELinux mode to $CURSELINUX"
    if [ $device == "Android" ];then
		su -c setenforce $CURSELINUX
    else
        adb shell "su -c setenforce $CURSELINUX"
    fi
    echo -e "\n\nT############# Test results"
    echo -e "\nREQSDK=$REQSDK\nREQSU=$REQSU\nREQSEL=$REQSEL\n"
    echo -e "\nTests finished! Check the above output!"
    echo -e "If any of the REQxxx are set to <notok> then FIsH will not work for you atm."
    echo -e "Check the above messages to fix this and re-run the check afterwards."
    echo -e "Exiting here because in checking mode. Nothing got installed.\n\n"
    exit
fi

if [ $device == "Android" ];then
	echo "############# remount /system"
	RET=$(su -c 'mount -oremount,rw /system; echo err=$?' | grep err=|tr -d '\r') # bullshit.. mount do not return a valid errorcode!
	#F_ERR $RET
	echo "############# cleaning"
	RET=$(su -c rm -Rf /data/local/tmpfish/; echo err=$? | grep err= |tr -d '\r')
	F_ERR $RET
	RET=$(su -c rm -f /system/su.d/FIsH; echo err=$? | grep err= |tr -d '\r')
	F_ERR $RET
	RET=$(su -c rm -f /system/su.d/callmeFIsH; echo err=$? | grep err= |tr -d '\r')
	F_ERR $RET
	RET=$(su -c rm -Rf /system/fish; echo err=$? | grep err= |tr -d '\r')
	F_ERR $RET
	echo "############# creating temporary directory"
	RET=$(su -c mkdir /data/local/tmpfish; echo err=$? | grep err=|tr -d '\r')
	F_ERR $RET
	RET=$(su -c chmod 777 /data/local/tmpfish; echo err=$? | grep err=|tr -d '\r')
	F_ERR $RET
	echo "############# pushing files"
	for fishes in $(find fishing/ -type f );do cp $fishes /data/local/tmpfish/;done
	RET=$(su -c chmod 755 /data/local/tmpfish/gofishing.sh; echo err=$? | grep err=|tr -d '\r')
	F_ERR $RET
	echo "############# injecting the FIsH"
	RET=$(su -c /data/local/tmpfish/gofishing.sh; echo err=$? | grep err=|tr -d '\r')
	F_ERR $RET
	echo "############# remount /system RO again"
	RET=$(su -c mount -oremount,ro /system; echo err=$? | grep err=|tr -d '\r') # bullshit.. mount do not return a valid errorcode!
	#F_ERR $RET
	echo "############# restoring SELinux mode to $CURSELINUX"
	RET=$(su -c setenforce $CURSELINUX; echo err=$? | grep err= |tr -d '\r')
	F_ERR $RET
else
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
fi
echo "ALL DONE! Reboot and enjoy the FIsH."
echo
echo -e "Get support on IRC:\n"
echo -e "\tInstall HexChat (https://hexchat.github.io) -> channel #Carbon-user on freenode"
echo -e "\tor"
echo -e "\tjust open http://webchat.freenode.net/?channels=Carbon-user"
echo 
echo

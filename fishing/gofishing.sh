#!/system/bin/sh
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

FISHFOOD=fishfood.gz    # <-- do not change. or if: change it in the whole FIsH 
FISHDIR=/system/fish
TMPDIR=/data/local/tmpfish

#######################################
# Functions
#######################################
# Function to clean temp files
CLEANFILES() {
	# cleaning temp files
	echo " "
	echo "------- Cleaning files ------"
        echo "cleaning -> $TMPDIR"
	busybox rm -rf $TMPDIR
}

# function to detect the device and version installed

#######################################
# Main script
#######################################
echo ""
echo "--- mounting system as rw ---"

# remounting system as read and write
chmod 755 $TMPDIR/busybox
$TMPDIR/busybox mount -o remount, rw /system

echo ""
echo "--- installing busybox ------"
echo ""

[ -d $FISHDIR ] && rm -Rf $FISHDIR && echo previous FIsH installation removed

# add recovery dirs
echo "adding $FISHDIR dir..."
mkdir $FISHDIR

# adding custom busybox
echo "copying files..."
dd if=$TMPDIR/fishfood.release of=$FISHDIR/fishfood.release
dd if=$TMPDIR/busybox of=$FISHDIR/busybox
chown root.shell $FISHDIR/busybox
chmod 755 $FISHDIR/busybox
dd if=$TMPDIR/busybox of=/system/xbin/busybox
chown root.shell /system/xbin/busybox
chmod 755 /system/xbin/busybox
echo ""
echo "installing..."
/system/xbin/busybox --install -s /system/xbin
echo "                  [OK]"

echo ""
echo "---- preparing the FIsHFOOD ----"

# FIsHFOOD RAMdisk
if [ -f $FISHDIR/$FISHFOOD ]; then
	rm $FISHDIR/$FISHFOOD
    echo ""
	echo "old FIsHFOOD ramdisk removed..."
fi

# adding FIsHFOOD
echo ""
echo "adding FIsHFOOD Ramdisk..."
dd if=$TMPDIR/$FISHFOOD of=$FISHDIR/$FISHFOOD
chown root.shell $FISHDIR/$FISHFOOD
chmod 644 $FISHDIR/$FISHFOOD

# create su.d if needed
if [ ! -d /system/su.d ]; then
	echo ""
	echo "preparing su dir"
	mkdir /system/su.d
fi

# adding fish
echo ""
echo "adding FIsH..."
dd if=$TMPDIR/callmeFIsH of=/system/su.d/callmeFIsH
dd if=$TMPDIR/FIsH of=/$FISHDIR/FIsH
dd if=$TMPDIR/FIsH.me of=/$FISHDIR/FIsH.me
dd if=$TMPDIR/FIsH.porting of=/$FISHDIR/FIsH.porting
chown root.shell /system/su.d/callmeFIsH
chmod 755 /system/su.d/callmeFIsH

# cleaning temp files
CLEANFILES

# verifying
echo ""
if [ -f /system/su.d/callmeFIsH ] && [ -f $FISHDIR/$FISHFOOD ] && [ -f $FISHDIR/busybox ] && [ -f $FISHDIR/FIsH ];then
	echo "FIsH successfully prepared! Enjoy the meal!"
else
	echo "Something goes wrong!!!!"
fi

echo " "
echo "              [ all done! ] "
echo " "

# remounting system as read only
mount -o remount, ro /system

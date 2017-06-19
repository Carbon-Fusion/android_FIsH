### Disclaimer

_FIsH does NOT unlock your bootloader or root your phone - it requires root to work though!
FIsH itself will NOT let you "install" anything. 
FIsH is actually the FRAMEWORK(!) for a custom FIsHFOOD (ramdisk) you want to load (e.g. TWRP).
FIsH does not ship with any FIsHFOOD so you need to compile/add your own!_

_For problems with the FIsHFOOD (e.g. TWRP) contact the developer of the FIsHFOOD instead! 
Nevertheless if you feel that FIsH is responsible for an issue with the FIsHFOOD proceed_

- [X] I know and understand that FIsH provides the **FRAMEWORK** for custom ramdisks only

### Contribution

_Any help in the development is welcome so if you want to add new functionality or fixing a bug in FIsH just went over to:_

_[Our Gerrit](https://gerrit.nailyk.fr/#/admin/projects/android_FIsH)!_


### Vendor & Model

**PROVIDE THE EXACT MODEL NAME OF YOUR DEVICE!**

_(remove all not matching lines)_

- issue is not related to a specific device or vendor
- HTC
- Samsung
- LG
- other (TELL ME WHICH!)

### Description

_describe your bug report, feature request and be as detailed as possible_
_Logfiles and bigger pastes better goes to an external pastebin service like for example: http://paste.omnirom.org_

- Detailed description of the issue:


### Logs

_Catch the FIsH logs! **WITHOUT THEM NO HELP!**_

1. _when in TWRP (or other ramdisk providing adb shell):
adb shell "cat /cache/fish/fish.log"
adb shell "cat /tmp/recovery.log"
1. OR - when in Android:
adb shell "su -c cat /cache/fish/fish.log"
adb shell "su -c cat /cache/fish/fish.log.old"
adb shell "su -c tar cvzf recoverylogs.tgz /cache/recovery"
1. adb pull recoverylogs.tgz
1. Upload the output to https://paste.omnirom.org and paste the link in the IRC channel_

- add your link(s) to the FIsH logs here: 

### Links

_If you have any other ressource might helping to solve the issue (XDA post, screenshot,...) add them here_
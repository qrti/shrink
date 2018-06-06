#!/bin/bash

# shrink V0.71 180527 qrt@qland.de
# linux bash script to resize Raspberry SD card images 
#
# inspired by
# http://www.aoakley.com/articles/2015-10-09-resizing-sd-images.php
#
# necessary installs
# sudo apt-get update && sudo apt-get install dcfldd
# sudo apt-get update && sudo apt-get install gparted

DEVICE="/dev/sdd"           # source and target SD card device, examples: /dev/sdd, /dev/mmcblk0 ...
USER="your user name"       # linux user name
IMAGE_NAME="image"          # image name, alternative with date and time: "image_$(date +"%y%m%d%H%M%S")"
IMAGE="${IMAGE_NAME}.img"   # image name with extension
LOOP=$(losetup -f)

READ=true                   # read image from SD card (false for an already existing image)
RESIZE=true                 # resize image with GParted
FILL=true                   # fill empty space of new image with zeroes, only possible if RESIZE=true
COMPRESS=false              # compress new image (an extra file is generated)
WRITE=false                 # write new image to SD card

pause(){
    printf "\n"
    printf "$1\n"
    read -p "press [Enter] to continue, CTRL-C to abort" key
    printf "\n"
}

checkDevice(){
    if [ "$1" == "" -o "$(df -h --output=source | grep "$DEVICE")" == "" ]; then
        printf "device '$1' does not exist\n"
        printf "> check SD card devices with 'df -h'\n"
        printf "> re-insert SD card if necessary\n"
        printf "> edit DEVICE= in script if necessary\n\n"
        exit 1
    fi
}

echo "shrink V0.71 180527 qrt@qland.de"

if [ $(id -u) -ne 0 ]; then
    printf "\n"
    printf "script must be run as root\n"
    printf "> try 'sudo ./shrink'\n\n"
    exit 1
fi

if [ "$USER" == "" ]; then
    printf "\n"
    printf "user not set\n"
    printf "> edit USER= in script\n\n"
    exit 1
fi

if [ $READ == true ]; then
    if [ -f $IMAGE ]; then
        pause "file '$IMAGE' already exists and will be overwritten"
        echo -ne '\033[1A'              # one line up
    fi

    pause "insert source SD card and >>> close all popup file manager windows <<<"
    checkDevice $DEVICE

    sudo umount $DEVICE?*               && echo unmount    ok || exit 1
    sudo dcfldd if=$DEVICE of=$IMAGE    && echo image read ok || exit 1
    sudo sync

    pause "remove SD card"
    echo -ne '\033[1A'                  # one line up
fi

echo
sudo chown $USER.$USER $IMAGE           && echo owner and group ok || exit 1

if [ $RESIZE == true ]; then
    #sudo fdisk -l $IMAGE
    #read -p "enter Start of part 2: " start
    start="$(sudo parted $IMAGE -ms unit s print | grep "^2" | cut -f2 -d: | sed 's/[^0-9]*//g')"

    sudo losetup -d $LOOP >/dev/null 2>&1  # remove possible open loop
    sudo losetup $LOOP $IMAGE -o $((start*512)) && echo loop setup ok || exit 1

    echo
    echo "GParted desktop is started now"
    echo "- go to GParted desktop window"
    echo "- select '$LOOP'"
    echo "- menu 'Partition / Resize/Move'"
    echo "- change value of 'New Size' about >= 250 MB above 'Minimum Size'"
    echo "- press button 'Resize/Move'"
    echo "- menu 'Edit / Apply All Operations' and press Apply"
    echo "- wait until GParted is ready - do not close dialog yet"
    echo "- expand 'Details / Shrink.. / shrink.. / resize2fs -p $LOOP xxxxxxxK'"
    echo "- note down size xxxxxxx"
    echo "- close dialog and exit GParted"

    sudo gparted $LOOP >/dev/null 2>&1     # supresses GLib messages

    echo
    read -p "enter noted size xxxxxxxx: " size
    echo

    sudo losetup -d $LOOP          && echo loop remove ok || exit 1
    sudo losetup $LOOP $IMAGE      && echo loop setup  ok || exit 1

    newsize="+${size}K"
    printf "d\n2\nn\np\n2\n$start\n$newsize\np\nw\n" | sudo fdisk $LOOP >/dev/null 2>&1
    echo resize ok

    #sudo fdisk -l $LOOP
    #read -p "enter End of part 2: " end
    end="$(sudo parted $LOOP -ms unit s print | grep "^2" | cut -f3 -d: | sed 's/[^0-9]*//g')"

    sudo losetup -d $LOOP          && echo loop remove ok || exit 1
    truncate -s $(((end+1)*512)) $IMAGE && echo truncate    ok || exit 1

    if [ $FILL == true ]; then
        echo
        echo fill empty space
        sudo losetup $LOOP $IMAGE -o $((start*512))
        sudo mkdir -p /mnt/imageroot
        sudo mount $LOOP /mnt/imageroot
        sudo dcfldd if=/dev/zero of=/mnt/imageroot/zero.txt
        sudo rm /mnt/imageroot/zero.txt
        sudo umount /mnt/imageroot
        sudo rmdir /mnt/imageroot
        sudo losetup -d $LOOP
        echo fill empty space ok
    fi
fi

if [ $COMPRESS == true ]; then
    echo
    echo compress image
    zip $IMAGE_NAME.zip $IMAGE          && echo compress    ok || echo compress    failed
fi

if [ $WRITE == true ]; then
    pause "insert target SD card and >>> close all popup file manager windows <<<"
    checkDevice $DEVICE

    sudo umount $DEVICE?*               && echo unmount     ok || exit 1
    sudo dcfldd if=$IMAGE of=$DEVICE    && echo image write ok || exit 1
    sudo sync

    echo
    echo remove SD card
fi

echo
echo ready
echo

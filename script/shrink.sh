#!/bin/bash

# shrink V0.81 180707 qrt@qland.de
# linux bash script to resize Raspberry SD card images, progress version
#
# inspired by
# http://www.aoakley.com/articles/2015-10-09-resizing-sd-images.php

# make script executable once
# chmod a+x shrink.sh

# necessary installs
# sudo apt-get install gparted
# sudo apt-get install pv

###
# configuration
# default values can be overridden by passing them as env vars
# e.g. sudo DEVICE=/dev/sda READ=false ./shrink.sh
###

SHRINK_VERSION="V0.81 180707"

trap 'echo "Aborting due to errexit on line $LINENO. Exit code: $?" >&2' ERR


USER=${USER:-`whoami`}                    # specify user who should own output files
DEVICE=${DEVICE:-/dev/sdb}                # source and target SD card device, examples: /dev/sdd, /dev/mmcblk0 ...
IMAGE_NAME=${IMAGE_NAME:-image}           # image name, alternative with date and time: "image_$(date +"%y%m%d%H%M%S")"
IMAGE=${IMAGE:-${IMAGE_NAME}.img}         # image name with extension
DETAILS=${DETAILS:-~/gparted_details.htm} # gparted details file path and name

READ=${READ:-true}              # read image from SD card (false for an already existing image)
RESIZE=${RESIZE:-true}          # resize image with GParted
FILL=${FILL:-true}              # fill empty space of new image with zeroes, only possible if RESIZE=true
COMPRESS=${COMPRESS:-false}     # compress new image (an extra file is generated)
WRITE=${WRITE:-false}           # write new image to SD card


LOOP=$(losetup -f)


_ME=$(basename "${0}")

_print_help() {
  cat <<HEREDOC
Shrink ${SHRINK_VERSION} qrt@qland.de

Linux bash script to resize Raspberry SD card images, progress version.

Inspired by:
   http://www.aoakley.com/articles/2015-10-09-resizing-sd-images.php

Necessary steps:
  make script executable once
  chmod a+x shrink.sh

Necessary installs:
  sudo apt-get install gparted
  sudo apt-get install pv

Usage:
  (sudo) ${_ME} [<arguments>]
  (sudo) ${_ME} -h | --help
  (sudo) ${_ME} --start

Options:
  -h --help             Show this screen
  --user                specify user who should own output files (default: ${USER})
  --device              source and target SD card device (default: ${DEVICE})
  --date_name           image name, alternative with date and time: "image_$(date +"%y%m%d%H%M%S") (default: ${IMAGE_NAME})"
  --image               image name with extension (default: ${IMAGE})
  --details             gparted details file path and name (default: ${DETAILS})
  --compress            compress new image (an extra file is generated) (default: ${COMPRESS})
  --write               write new image to SD card (default: ${WRITE})
  --skip-read           read image from SD card (false for an already existing image) (default: ${READ})
  --skip-resize         resize image with GParted (default: ${RESIZE})
  --skip-fill           fill empty space of new image with zeroes, only possible if RESIZE=true (default: ${FILL})

HEREDOC
}

function _parse
{
    # Gather commands
    while (( "${#}" ))
    do
        case "${1}" in
            --user)
            USER="${2}"
            shift
            shift
            ;;
            --device)
            DEVICE="${2}"
            shift
            shift
            ;;
            --date_name)
            IMAGE_NAME="image_$(date +"%y%m%d%H%M%S")"
            shift
            ;;
            --image)
            IMAGE="${2}"
            shift
            shift
            ;;
            --details)
            DETAILS="${2}"
            shift
            shift
            ;;
            --skip-read)
            READ=false
            shift
            ;;
            --skip-resize)
            RESIZE=false
            shift
            ;;
            --skip-fill)
            FILL=false
            shift
            ;;
            --compress)
            COMPRESS=true
            shift
            ;;
            --write)
            WRITE=true
            shift
            ;;
            *|-*|--*=) # unsupported flags
            echo "Unknown ${1}"
            exit 1
            ;;
        esac
    done
}


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

function _main
{
    echo "shrink ${SHRINK_VERSION} qrt@qland.de"

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
        bsize="$(($(blockdev --getsize64 $DEVICE)/1024))K"
        sudo umount $DEVICE?*               && echo unmount    ok || exit 1
        echo
        echo "generate image from SD card"
        sudo dd if=$DEVICE status=none | pv -s $bsize | dd of=$IMAGE bs=4096 status=none \
                                            && echo image read ok || exit 1
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

        sudo losetup -d ${LOOP} >/dev/null 2>&1  # remove possible open loop
        sudo losetup ${LOOP} ${IMAGE} -o $((start*512)) && echo loop setup ok || exit 1

        echo
        echo "GParted desktop is started now"
        echo "- go to GParted desktop window"
        echo "- select '$LOOP'"
        echo "- menu 'Partition / Resize/Move'"
        echo "- change value of 'New Size' about >= 250 MB above 'Minimum Size'"
        echo "- press button 'Resize/Move'"
        echo "- menu 'Edit / Apply All Operations' and press Apply"
        echo "- wait until GParted is ready - do not close dialog yet"
        echo "- press button 'Save Details' and 'Save' in file requester"
        echo "- close dialog and exit GParted"
        echo

        rm -f ~/gparted_details.htm         # remove old details

        sudo gparted $LOOP >/dev/null 2>&1  # supresses GLib messages

        if [ ! -f $DETAILS ]; then          # check details exist
            echo "gparted details file not found"
            exit 1
        fi

        size=$(awk '/resize2fs -p / {print $4;}' $DETAILS | awk 'BEGIN { FS="K"; } { print $1; }')

        rm -f ~/gparted_details.htm         # remove details

        if [ -z $size ]; then               # check size
            echo "size not found in details"
            exit 1
        elif [ $size -lt 512000 ]; then
            echo "suspicious small filesize"
            exit 1
        fi

        sudo losetup -d $LOOP               && echo loop remove ok || exit 1
        sudo losetup $LOOP $IMAGE           && echo loop setup  ok || exit 1

        newsize="+${size}K"
        printf "d\n2\nn\np\n2\n$start\n$newsize\np\nw\n" | sudo fdisk $LOOP >/dev/null 2>&1
        echo resize ok

        #sudo fdisk -l $LOOP
        #read -p "enter End of part 2: " end
        end="$(sudo parted $LOOP -ms unit s print | grep "^2" | cut -f3 -d: | sed 's/[^0-9]*//g')"

        sudo losetup -d $LOOP               && echo loop remove ok || exit 1
        truncate -s $(((end+1)*512)) $IMAGE && echo truncate    ok || exit 1

        if [ $FILL == true ]; then
            echo
            echo fill empty space
            sudo losetup $LOOP $IMAGE -o $((start*512))
            sudo mkdir -p /mnt/imageroot
            sudo mount $LOOP /mnt/imageroot
            bsize="$(($(df -h -B1K | grep ^$LOOP | awk '{print $4}')*11/10))K"      # +10% progress bar fs overhead correction
            sudo dd if=/dev/zero | pv -s $bsize | dd of=/mnt/imageroot/zero.txt >/dev/null 2>&1
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
        tar pcf - $IMAGE | pv -s $(du -sb $IMAGE | awk '{print $1}') | gzip > $IMAGE_NAME.tar.gz \
                                            && echo compress    ok || echo compress    failed
    fi

    if [ $WRITE == true ]; then
        pause "insert target SD card and >>> close all popup file manager windows <<<"
        checkDevice $DEVICE
        bsize="$(($(blockdev --getsize64 $DEVICE)/1024))K"
        sudo umount $DEVICE?*               && echo unmount     ok || exit 1
        echo
        echo "write image to SD card"
        sudo dd if=$IMAGE status=none | pv -s $bsize | dd of=$DEVICE bs=4096 status=none \
                                            && echo image write ok || exit 1
        sudo sync

        echo
        echo remove SD card
    fi

    echo
    echo ready
    echo
}


if [[ "${1:-}" =~ ^-h|--help$ ]]
then
    _print_help
else
    echo "calling parser"
    _parse "$@"
    _main "$@"
fi

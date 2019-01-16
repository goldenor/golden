#!/bin/bash

#########################################################################################
#                                                                                       #
#       File  : ./script.sh                                                             #
#       Usage : ./script.sh                                                             #
#       Description : Encrypt/Decrypt floppy devices                                    #
#       Option: -                                                                       #
#       Requirement : Floppy(USB)                                                       #
#       Bugs   : None                                                                   #
#       Author : Mouad OURGH                                                            #
#       Version: 1.0                                                                    #
#       Date   : 16/01/2019                                                             #
#                                                                                       #
#########################################################################################
device=$2
choice=$1
echo "$device $choice"
function isPGinstalled {
        if yum install gnupg >/dev/null 2>&1 ; then
        echo "OK"
        else
        yum install gnupg >/dev/null 2>&1
        "Installation GnuPG finished"
        fi
}

function isCRPinstalled {
        if yum list installed cryptsetup >/dev/null 2>&1 ; then
        echo "OK"
        else
        yum install cryptsetup >/dev/null 2>&1
        "Installation CryptSetup finished"
        fi
}

function second_action_conf {
cryptsetup -c aes-xts-plain --batch-mode -y -s 512 --key-file /keyfile luksFormat /dev/${device} || echo "F1"
cryptsetup --key-file /keyfile luksOpen /dev/${device} usb || echo "F2"
mkdir /mnt/flo || echo "F3"
mkfs.ext4 /dev/mapper/usb || echo "F4"
mount -t ext4 /dev/mapper/usb /mnt/flo || echo "F5"
}

function fisrt_action_gpg {
dd if=/dev/urandom of=/keyfile bs=512 count=16
#gpg -c --cipher-algo AES256 /keyfile
#rm -f /keyfile
}

function Use_usb {
cryptsetup luksOpen --key-file /keyfile /dev/${device} usb
        if [ $? -eq "0" ] ; then
        #if cryptsetup isLuks /dev/${device} ;then
                mount -t ext4 /dev/mapper/usb /mnt/flo
                cd /mnt/flo
        else
                echo "Cannot open /mnt/flo"
        fi
}
function Close_usb {

        umount /mnt/flo
        cryptsetup luksClose /dev/mapper/usb
}
function Open_Close {
if [ -e /keyfile ];then
        echo "Keyfile exist" 
        k_file=/keyfile
else
    while [ ! -e ${k_file} ]
    do
    read -p "the keyfile doesn't exist please enter the path complet path of the keyfile" k_file
    done
    echo "Keyfile exist"
fi
case $choice in
    "m")
        echo "Open..."
        cryptsetup luksOpen --key-file ${k_file} /dev/${device} usb
        echo "Mounting..."
        mount -t ext4 /dev/mapper/usb /mnt/flo && echo "done."
        
        ;;
    "u")
        echo "Unmounting..."
        cd /
        umount /mnt/flo && echo "done."
        echo "Closing encrypted partition..."
        cryptsetup luksClose /dev/mapper/usb && echo "done."
        ;;
    *)
                echo "Enter sh script.sh m == to mount or sh script.sh u == to umount"
           ;;
esac
}

lsblk
echo "sh script.sh (m/u) (Device_name ex:sdb1)"
#read -p "What is the name of your Device" device
cryptsetup isLuks /dev/${device}
        if [ $? -eq "0" ];then
                Open_Close
        else

                isPGinstalled
                isCRPinstalled
                fisrt_action_gpg
                second_action_conf
        fi

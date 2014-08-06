##########################################
#Ubuntu boot script V6.1 for Android     #
#Built by Zachary Powell (zacthespack)   #
#Thanks to:                              #
#Johan (sciurius)                        #
#Marshall Levin                          #
#and to everyone at XDA!                 #
##########################################
#Check for root                          #
##########################################
perm=$(id|cut -b 5)
if [ "$perm" != "0" ];then echo "This script requires root! Type: su"; exit; fi
mount -o remount,rw /dev/block/mmcblk0p5 /system
##########################################
#Set up veriables                        #
##########################################
export kit=$(dirname $0)
export bin=/system/bin
export mnt=/data/local/mnt
export USER=root
if [[ ! -d $mnt ]]; then mkdir $mnt; fi
export PATH=$bin:/usr/bin:/usr/local/bin:/usr/sbin:/bin:/usr/local/sbin:/usr/games:$PATH
export TERM=linux
export HOME=/root
##########################################
#Set up loop device                      #
##########################################
if [ -b /dev/block/loop255 ]; then
	echo "Loop device exists"
else
	busybox mknod /dev/block/loop255 b 7 255
fi
#mount -o loop,noatime -t ext4 $kit/ubuntu.img $mnt
busybox losetup /dev/block/loop255 $kit/ubuntu.img
##########################################
#Mount all required partitions           #
##########################################
busybox mount -t ext4 /dev/block/loop255 $mnt
busybox mount -t devpts devpts $mnt/dev/pts
busybox mount -t proc proc $mnt/proc
busybox mount -t sysfs sysfs $mnt/sys
busybox mount -o bind /sdcard $mnt/sdcard

##########################################
#Checks if you have a external sdcard    #
#and mounts it if you do                 #
##########################################
if [ -d /sdcard/external_sd ]; then
	busybox mount -o bind /sdcard/external_sd  $mnt/external_sd
fi
if [ -d /Removable/MicroSD ]; then
	busybox mount -o bind /Removable/MicroSD  $mnt/external_sd
fi
##########################################
#Sets up network forwarding              #
##########################################
busybox sysctl -w net.ipv4.ip_forward=1
echo "nameserver 8.8.8.8" > $mnt/etc/resolv.conf
echo "nameserver 8.8.4.4" >> $mnt/etc/resolv.conf
echo "127.0.0.1 localhost" > $mnt/etc/hosts
echo "Ubuntu is configured with SSH and VNC servers that can be accessed from the IP:"
ifconfig eth0
echo " "
##########################################
#Chroot into ubuntu                      #
##########################################
busybox chroot $mnt /root/init.sh

##########################################
#Shut down ubuntu                        #
##########################################
echo "Shutting down Ubuntu ARM"
for pid in `lsof | grep $mnt | sed -e's/  / /g' | cut -d' ' -f2`; do kill -9 $pid >/dev/null 2>&1; done
sleep 5
umount $mnt/sdcard
umount $mnt/external_sd
umount $mnt/dev/pts
umount $mnt/proc
umount $mnt/sys
umount $mnt
losetup -d /dev/block/loop255
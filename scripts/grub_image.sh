
#imagefile=grub_boot.qcow2
# qemu-img create -f qcow2 -o preallocation=metadata qcow2-blank.image 512M

imagefile=$1
mountpoint=/tmp/grubimage

modprobe nbd max_part=8
qemu-nbd --connect=/dev/nbd0 $imagefile

# create partition table and partitions with gdisk
# create filesystem mkfs and mount
mount /dev/nbd0p2 $mountpoint

# install grub
grub-install --target=i386-pc /dev/nbd0 --boot-directory=$mountpoint/boot -s
# configure grub
grub-mkconfig -o /$mountpoint/boot/grub/grub.cfg

umount $mountpoint
qemu-nbd --disconnect /dev/nbd0
rmmod nbd

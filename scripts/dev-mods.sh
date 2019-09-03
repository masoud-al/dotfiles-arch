#!/bin/sh



for dev in $(ls -d /dev/*)
do
	echo $dev
	# udevadm info  $dev
done


for mod in $(ls /sys/module/)
do
	echo $mod
	ls -l /sys/module/$mod/drivers
done





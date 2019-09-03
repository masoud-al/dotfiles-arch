#!/bin/sh

for dev in $(ls /sys/class/net)
do
	if [[ "$dev" == *"lo"* ]]; then
	  continue
	fi
	if [[ ! -z $(grep DEVTYPE=wlan /sys/class/net/$dev/uevent) ]]; then
 	   continue
	fi
	MAC=$(cat /sys/class/net/$dev/address)
done

echo $MAC

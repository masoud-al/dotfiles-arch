#!/bin/sh

dirname=avr-micro-data
flashname=m348p
filename=$dirname/$flashname

#the follwoing rule should exist in udev for user-mode permission with group uucp

cmd='avrdude -p m328p -P usb -c usbtiny'


#print information about programmer and device
($cmd -v)

#for fuse escription http://eleccelerator.com/fusecalc/fusecalc.php?chip=atmega328p

#sample output for m328p with USBtiny programmer
# avrdude: Version 6.3, compiled on Nov  6 2016 at 21:45:03
#          Copyright (c) 2000-2005 Brian Dean, http://www.bdmicro.com/
#          Copyright (c) 2007-2014 Joerg Wunsch
#
#          System wide configuration file is "/etc/avrdude.conf"
#          User configuration file is "/home/masoud/.avrduderc"
#          User configuration file does not exist or is not a regular file, skipping
#
#          Using Port                    : usb
#          Using Programmer              : usbtiny
# avrdude: usbdev_open(): Found USBtinyISP, bus:device: 004:005
#          AVR Part                      : ATmega328P
#          Chip Erase delay              : 9000 us
#          PAGEL                         : PD7
#          BS2                           : PC2
#          RESET disposition             : dedicated
#          RETRY pulse                   : SCK
#          serial program mode           : yes
#          parallel program mode         : yes
#          Timeout                       : 200
#          StabDelay                     : 100
#          CmdexeDelay                   : 25
#          SyncLoops                     : 32
#          ByteDelay                     : 0
#          PollIndex                     : 3
#          PollValue                     : 0x53
#          Memory Detail                 :
#
#                                   Block Poll               Page                       Polled
#            Memory Type Mode Delay Size  Indx Paged  Size   Size #Pages MinW  MaxW   ReadBack
#            ----------- ---- ----- ----- ---- ------ ------ ---- ------ ----- ----- ---------
#            eeprom        65    20     4    0 no       1024    4      0  3600  3600 0xff 0xff
#            flash         65     6   128    0 yes     32768  128    256  4500  4500 0xff 0xff
#            lfuse          0     0     0    0 no          1    0      0  4500  4500 0x00 0x00
#            hfuse          0     0     0    0 no          1    0      0  4500  4500 0x00 0x00
#            efuse          0     0     0    0 no          1    0      0  4500  4500 0x00 0x00
#            lock           0     0     0    0 no          1    0      0  4500  4500 0x00 0x00
#            calibration    0     0     0    0 no          1    0      0     0     0 0x00 0x00
#            signature      0     0     0    0 no          3    0      0     0     0 0x00 0x00
#
#          Programmer Type : USBtiny
#          Description     : USBtiny simple USB programmer, http://www.ladyada.net/make/usbtinyisp/
# avrdude: programmer operation not supported
#
# avrdude: Using SCK period of 10 usec
# avrdude: AVR device initialized and ready to accept instructions
#
# Reading | ################################################## | 100% 0.01s
#
# avrdude: Device signature = 0x1e950f (probably m328p)
# avrdude: safemode: hfuse reads as DA
# avrdude: safemode: efuse reads as FD
#
# avrdude: safemode: hfuse reads as DA
# avrdude: safemode: efuse reads as FD
# avrdude: safemode: Fuses OK (E:FD, H:DA, L:FF)
#
# avrdude done.  Thank you.



#formats
# r    raw binary; little-endian byte order, in the case of the flash ROM data
# i    Intel Hex

mkdir -p  $dirname


($cmd flash:r:$filename-flash.bin:r)
($cmd lfuse:r:$filename-lfuse.bin:r)
($cmd hfuse:r:$filename-hfuse.bin:r)
($cmd efuse:r:$filename-efuse.bin:r)
($cmd lock:r:$filename-lock.bin:r)
($cmd calibration:r:$filename-calibration.bin:r)
($cmd signature:r:$filename-signature.bin:r)

#writing
#($cmd -U flash:w:$filename-flash.bin:r)

#verifying
#($cmd -U flash:v:$filename-flash.bin:r)

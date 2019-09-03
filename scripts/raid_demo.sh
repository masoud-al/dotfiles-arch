#!/bin/sh

# this script is based on the template from 
# https://agateau.com/2014/template-for-shell-based-command-line-scripts/

set -e

PROGNAME=$(basename $0)

ndev=8
last=$(expr $ndev - 1)
size=64M
raiddev=/dev/md/MtRAID6
mtpt=raidpt
ids=$(seq 0 $(expr $ndev - 1))

COMMANDS="create|stop|clean|fail"

command=""
subc=""
flag=0
count="8"

die() {
    echo "$PROGNAME: $*" >&2
    exit 1
}

usage() {
    if [ "$*" != "" ] ; then
        echo "Error: $*"
    fi

    cat << EOF
Usage: $PROGNAME [OPTION ...] <command>
A simple demo about using mdadm RAID configuration using qcow2 images.
commands = $COMMANDS

Options:
-h, --help          display this usage message and exit
-d, --flag          flag
-c, --count [n]     number of devices
EOF

    exit 1
}

create(){
   echo "${ndev} qcow2 images ..."
   seq 0 ${last} | parallel qemu-img create -f qcow2 -o preallocation=metadata storage-{}.qcow2 ${size}

   modprobe nbd max_part=${ndev}
   seq 0 ${last} | parallel qemu-nbd --connect=/dev/nbd{} storage-{}.qcow2
   sleep 0.5
   seq 0 ${last} | parallel sgdisk /dev/nbd{} -n 0:0:+60M -t 0:FD00
   sleep 0.5
    
   nd=$(expr $ndev - 3)
   mdadm --create --verbose ${raiddev} -N MtRAID6 -l6 -n${nd} -x3 /dev/nbd*p1
   mdadm --detail ${raiddev}	
   mkfs.ext4 ${raiddev}
   mkdir -p ${mtpt}
   mount ${raiddev} ${mtpt}
   mdadm --detail --scan --verbose > mdadm.conf	
}

stop(){ 
   umount ${raiddev} || true
   mdadm --stop ${raiddev} || true
}

clean(){
   stop
   rm -r ${mtpt} || true
   seq 0 ${last} |  parallel qemu-nbd --disconnect /dev/nbd{}  
   sleep 1
   modprobe -r nbd || true
}

fail(){
   echo "declare one device as failed"
   mdadm --fail ${raiddev} /dev/nbd0p1
   # mdadm --remove ${raiddev} /dev/nbd0p1
   # mdadm --zero-superblock /dev/nbd0p1
   sleep 1
   mdadm --detail ${raiddev}
}



while [ $# -gt 0 ] ; do
    case "$1" in
    -h|--help)
        usage
        ;;
    -d|--flag)
        flag=1
        ;;
    -o|--count)
        count="$2"
        shift
        ;;
    -*)
        usage "Unknown option '$1'"
        ;;
    *)
        if [ -z "$command" ] ; then
            command="$1"	
        elif [ -z "$subc" ] ; then
            subc="$1"
        else
            usage "Too many arguments"
        fi
        ;;
    esac
    shift
done

if [ -z "$command" ] ; then
    usage "Not enough arguments"
fi


if [[ "$command" =~ ^${COMMANDS}$ ]]; then
    $command 	
fi


#cat <<EOF
#command=$command
#subc=$subc
#flag=$flag
#count=$count
#EOF



# alias par="parallel --no-run-if-empty --dryrun"
# mdadm --monitor  /dev/md/test_raid
# mdadm --misc --zero-superblock /dev/<partition>





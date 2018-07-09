#!/bin/sh
# this script sets the environment variable to a custom path 
# It can be used to test a local installation without poluting 
# system root
# usage source custom-root <path>
root=$1
export PATH=$PATH:$root/bin
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$root/lib
export LDFLAGS="$LDFLAGS -L$root/lib"
export PKG_CONFIG_PATH=$PKG_CONFIG_PATH:$root/lib/pkgconfig
export CFLAGS="$CFLAGS -I$root/include"
# cmake .. -DCMAKE_INSTALL_PREFIX:PATH=$root
# ./configure --prefix=$root
# PREFIX=$root make



export PYTHONPATH=$root/lib/python2.7/site-packages


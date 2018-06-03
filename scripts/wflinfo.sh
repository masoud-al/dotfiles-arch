#!/bin/sh
platforms="android cgl gbm glx wayland wgl x11_egl"
apis="gl gles1 gles2 gles3"

for p in $platforms
do
 for a in $apis
 do
  echo "platfor=$p, api=$a" 
  wflinfo -p $p -a $a
  echo "------------------------"
 done	
done


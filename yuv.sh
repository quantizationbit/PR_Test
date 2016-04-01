#!/bin/bash


#ffmpeg -y -i Lr_5minClip_HDR_UHD2160_240_ProRes4444_rec2020_PQ_1000nits_2398p_Clipster6Test.mov \
   #-an  -vcodec tiff tif/%06d.tif
   
   
# Create YUV
# Build YUV
rm -fv YUV.yuv
for filename in tif/*.tif ; do

ctlrender -force -ctl $EDRHOME/ACES/CTLa1/Full-2-VideoRange.ctl \
 $filename /dev/shm/temp.tif
$EDRHOME/Tools/YUV/tif2yuv /dev/shm/temp.tif B10 2020  -o YUV.yuv



done

rm -fv /dev/shm/temp.tif
   

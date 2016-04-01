#!/bin/bash

set -x

#ffmpeg -y -i Lr_5minClip_HDR_UHD2160_240_ProRes4444_rec2020_PQ_1000nits_2398p_Clipster6Test.mov \
   #-an  -vcodec tiff tif/%06d.tif
   
   
# Create YUV
# Build YUV
rm -fv YUV.yuv
#for filename in tif/*.tif ; do

#ctlrender -force -ctl $EDRHOME/ACES/CTLa1/Full-2-VideoRange.ctl \
 #$filename /dev/shm/temp.tif
#$EDRHOME/Tools/YUV/tif2yuv /dev/shm/temp.tif B10 2020  -o YUV.yuv

#done

#rm -fv /dev/shm/temp.tif
   



# find all exr files
c1=0
CMax=7


for filename in tif/*.tif ; do

 
if [ $c1 -le $CMax ]; then

ctlrender -force -ctl $EDRHOME/ACES/CTLa1/Full-2-VideoRange.ctl \
 $filename /dev/shm/temp$c1".tif" &



c1=$[$c1 +1]
fi

if [ $c1 -gt $CMax ]; then
for job in `jobs -p`
do
echo $job
wait $job 
done
c1=0
# put in YUV frames
for i in $(seq 0 $CMax); do
$EDRHOME/Tools/YUV/tif2yuv /dev/shm/temp$i".tif" B10 2020  -o YUV.yuv
done

fi



done


# make sure all jobs finished
for job in `jobs -p`
do
echo $job
wait $job 
done


# put in YUV frames
for i in {0..$c1}; do
$EDRHOME/Tools/YUV/tif2yuv /dev/shm/temp$i".tif" B10 2020  -o YUV.yuv
done



# cleanup
rm -fv /dev/shm/temp*tif



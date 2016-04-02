#!/bin/bash

set -x




ctlrender -force -ctl $EDRHOME/ACES/CTLa1/PQ2020-2-709Gamma.ctl \
 $filename tif/006534.tif  1000-006534.tif &


ctlrender -force -ctl $EDRHOME/ACES/CTLa1/PQ2020-2-709Gamma.ctl -param1 CLIP 800.0\
 $filename tif/006534.tif  800-006534.tif &
 
 
 ctlrender -force -ctl $EDRHOME/ACES/CTLa1/PQ2020-2-709Gamma.ctl -param1 CLIP 500.0\
 $filename tif/006534.tif  500-006534.tif &
 
  
 ctlrender -force -ctl $EDRHOME/ACES/CTLa1/PQ2020-2-709Gamma.ctl -param1 CLIP 250.0\
 $filename tif/006534.tif  250-006534.tif &
 
  
 ctlrender -force -ctl $EDRHOME/ACES/CTLa1/PQ2020-2-709Gamma.ctl -param1 CLIP 100.0\
 $filename tif/006534.tif  100-006534.tif &




for job in `jobs -p`
do
echo $job
wait $job 
done




for filename in *006534.tif
do

 # file name w/extension e.g. 000111.tiff
 cFile="${filename##*/}"
 # remove extension
 cFile="${cFile%.tif}"
 # note cFile now does NOT have tiff extension!
 #echo -e "crop: $filename \n"

convert $filename -quality 90 $cFile".jpg" &

done

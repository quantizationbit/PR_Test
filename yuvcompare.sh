


function FRAMETEST {

export CTL_MODULE_PATH="/usr/local/lib/CTL:$EDRHOME/ACES/CTL:$EDRHOME/ACES/transforms/ctl/utilities"

# Dump frame
rm -rfv tifRGB444
mkdir tifRGB444
ffmpeg -y -i ../$prores \
   -an  -vcodec tiff tifRGB444/%06d.tif
   
ctlrender -force -ctl $EDRHOME/ACES/CTL/null.ctl \
          tifRGB444/"000002.tif" tifRGB444/"000002ctl.tif"    
$EDRHOME/Tools/tifcmp/tifcmp $f834 tifRGB444/"000002ctl.tif"  B10 -o 127.0 | tee "PSNR_FFMPEG_RT-"$run".txt"


# Dump a 420 using ffmpeg (assuming only subsampling is occuring)
rm -rfv tifXYZ
mkdir tifXYZ
rm Direct.yuv
ffmpeg -y -i ../$prores \
   -an  -pix_fmt yuv420p10le  -f rawvideo -vcodec rawvideo  Direct.yuv

   
# assume prores is 2020 yuv 444 matrix
$EDRHOME/Tools/YUV/yuv2tif Direct.yuv B10 2020
rm -rfv tif2020
mv tifXYZ tif2020
ctlrender -force -ctl $EDRHOME/ACES/CTL/null.ctl \
                 -ctl $EDRHOME/ACES/CTL/VideoRange-2-Full.ctl \
          tif2020/"XpYpZp000002.tif" tif2020/"XpYpZp000002ctl.tif"
$EDRHOME/Tools/tifcmp/tifcmp $f834 tif2020/XpYpZp000002ctl.tif  B10 -o 127.0 | tee "PSNR_FFMPEG_RTw2020-"$run".txt"

# assume prores is 2020 Constant Luminance yuv 444 matrix
mkdir tifXYZ
$EDRHOME/Tools/YUV/yuv2tif Direct.yuv B10 2020C
rm -rfv tif2020C
mv tifXYZ tif2020C
ctlrender -force -ctl $EDRHOME/ACES/CTL/null.ctl \
                 -ctl $EDRHOME/ACES/CTL/VideoRange-2-Full.ctl \
          tif2020C/"XpYpZp000002.tif" tif2020C/"XpYpZp000002ctl.tif"
$EDRHOME/Tools/tifcmp/tifcmp $f834 tif2020C/XpYpZp000002ctl.tif  B10 -o 127.0 | tee "PSNR_FFMPEG_RTw2020C-"$run".txt"




#  try with 709 yuv matrix to see that there is difference
mkdir tifXYZ
$EDRHOME/Tools/YUV/yuv2tif Direct.yuv B10 709
rm -rfv tif709
mv tifXYZ tif709
ctlrender -force -ctl $EDRHOME/ACES/CTL/null.ctl \
                 -ctl $EDRHOME/ACES/CTL/VideoRange-2-Full.ctl \
          tif709/"XpYpZp000002.tif" tif709/"XpYpZp000002ctl.tif"
$EDRHOME/Tools/tifcmp/tifcmp $f834 tif709/XpYpZp000002ctl.tif  B10 -o 127.0 | tee "PSNR_FFMPEG_RTw709-"$run".txt"




# Sigma compare:
export CTL_MODULE_PATH="$EDRHOME/ACES/aces-dev/transforms/ctl/utilities:$EDRHOME/ACES/CTLa1"
rm -fv *exr

ctlrender -force -ctl $EDRHOME/ACES/CTLa1/PQ2Linear.ctl $f834 -param1 aIn 1.0 \
    -format exr16 Frame834.exr &
    
ctlrender -force -ctl $EDRHOME/ACES/CTLa1/PQ2Linear.ctl -param1 aIn 1.0 \
   tif2020/XpYpZp000002ctl.tif \
   -format exr16 F834_2020yuv.exr &
   
ctlrender -force -ctl $EDRHOME/ACES/CTLa1/PQ2Linear.ctl -param1 aIn 1.0 \
   tif2020C/XpYpZp000002ctl.tif \
   -format exr16 F834_2020Cyuv.exr &   
   
ctlrender -force -ctl $EDRHOME/ACES/CTLa1/PQ2Linear.ctl -param1 aIn 1.0 \
   tif709/XpYpZp000002ctl.tif \
   -format exr16 F834_709yuv.exr &
   
ctlrender -force -ctl $EDRHOME/ACES/CTLa1/PQ2Linear.ctl -param1 aIn 1.0 \
   tifRGB444/"000002ctl.tif" \
   -format exr16 F834_ffmpeg.exr &
   
# 10 bit file
$EDRHOME/Tools/tiftruncate/tiftruncate -i $f834 -o 10bit.tif -d 10
ctlrender -force -ctl $EDRHOME/ACES/CTLa1/PQ2Linear.ctl -param1 aIn 1.0 \
   10bit.tif \
   -format exr16 F834_10bit.exr &

# 12 bit file
$EDRHOME/Tools/tiftruncate/tiftruncate -i $f834 -o 12bit.tif -d 12
ctlrender -force -ctl $EDRHOME/ACES/CTLa1/PQ2Linear.ctl -param1 aIn 1.0 \
   12bit.tif \
   -format exr16 F834_12bit.exr &

# make sure all jobs finished
for job in `jobs -p`
do
echo $job
wait $job 
done

        
filename="sc2020yuv-"$run".log"
$EDRHOME/Tools/demos/sc/sigma_compare_PQ Frame834.exr F834_2020yuv.exr | tee $filename
rm -fv *data


sed -n -e /"PQ Ave"/p -e /"#10k16b-"/p $filename | sed -n -e /sigma_red/p -e /"#10k16b-"/p | sed s/"#10k16b-".*//g | sed -e s/"pixels, PQ Ave".*//g | sed -e s/"sigma_red".// | sed -e s/"] ="// | sed -e s/"self_relative =".*"(".*" ="// | sed s/" for"// | sed s/"pixels".*//  | tee X.data

sed -n -e /"PQ Ave"/p -e /"#10k16b-"/p $filename | sed -n -e /sigma_grn/p -e /"#10k16b-"/p | sed s/"#10k16b-".*//g | sed -e s/"pixels, PQ Ave".*//g | sed -e s/"sigma_grn".// | sed -e s/"] ="// | sed -e s/"self_relative =".*"(".*" ="// | sed s/" for"// | sed s/"pixels".*//  | tee Y.data

sed -n -e /"PQ Ave"/p -e /"#10k16b-"/p $filename | sed -n -e /sigma_blu/p -e /"#10k16b-"/p | sed s/"#10k16b-".*//g | sed -e s/"pixels, PQ Ave".*//g | sed -e s/"sigma_blu".// | sed -e s/"] ="// | sed -e s/"self_relative =".*"(".*" ="// | sed s/" for"// | sed s/"pixels".*//  | tee Z.data

# remove .log
export filename="${filename%.log}"

# use -p if want plots to stay up
gnuplot plot.gp

convert -alpha off -density 300 \
    $filename".eps" -resize 1440x1080  -quality 90 $filename".jpg"
    
    
filename="sc2020Cyuv-"$run".log"
$EDRHOME/Tools/demos/sc/sigma_compare_PQ Frame834.exr F834_2020Cyuv.exr | tee $filename
rm -fv *data


sed -n -e /"PQ Ave"/p -e /"#10k16b-"/p $filename | sed -n -e /sigma_red/p -e /"#10k16b-"/p | sed s/"#10k16b-".*//g | sed -e s/"pixels, PQ Ave".*//g | sed -e s/"sigma_red".// | sed -e s/"] ="// | sed -e s/"self_relative =".*"(".*" ="// | sed s/" for"// | sed s/"pixels".*//  | tee X.data

sed -n -e /"PQ Ave"/p -e /"#10k16b-"/p $filename | sed -n -e /sigma_grn/p -e /"#10k16b-"/p | sed s/"#10k16b-".*//g | sed -e s/"pixels, PQ Ave".*//g | sed -e s/"sigma_grn".// | sed -e s/"] ="// | sed -e s/"self_relative =".*"(".*" ="// | sed s/" for"// | sed s/"pixels".*//  | tee Y.data

sed -n -e /"PQ Ave"/p -e /"#10k16b-"/p $filename | sed -n -e /sigma_blu/p -e /"#10k16b-"/p | sed s/"#10k16b-".*//g | sed -e s/"pixels, PQ Ave".*//g | sed -e s/"sigma_blu".// | sed -e s/"] ="// | sed -e s/"self_relative =".*"(".*" ="// | sed s/" for"// | sed s/"pixels".*//  | tee Z.data

# remove .log
export filename="${filename%.log}"

# use -p if want plots to stay up
gnuplot plot.gp

convert -alpha off -density 300 \
    $filename".eps" -resize 1440x1080  -quality 90 $filename".jpg"
        
    
filename="sc709yuv-"$run".log"
$EDRHOME/Tools/demos/sc/sigma_compare_PQ Frame834.exr F834_709yuv.exr | tee $filename
rm -fv *data


sed -n -e /"PQ Ave"/p -e /"#10k16b-"/p $filename | sed -n -e /sigma_red/p -e /"#10k16b-"/p | sed s/"#10k16b-".*//g | sed -e s/"pixels, PQ Ave".*//g | sed -e s/"sigma_red".// | sed -e s/"] ="// | sed -e s/"self_relative =".*"(".*" ="// | sed s/" for"// | sed s/"pixels".*//  | tee X.data

sed -n -e /"PQ Ave"/p -e /"#10k16b-"/p $filename | sed -n -e /sigma_grn/p -e /"#10k16b-"/p | sed s/"#10k16b-".*//g | sed -e s/"pixels, PQ Ave".*//g | sed -e s/"sigma_grn".// | sed -e s/"] ="// | sed -e s/"self_relative =".*"(".*" ="// | sed s/" for"// | sed s/"pixels".*//  | tee Y.data

sed -n -e /"PQ Ave"/p -e /"#10k16b-"/p $filename | sed -n -e /sigma_blu/p -e /"#10k16b-"/p | sed s/"#10k16b-".*//g | sed -e s/"pixels, PQ Ave".*//g | sed -e s/"sigma_blu".// | sed -e s/"] ="// | sed -e s/"self_relative =".*"(".*" ="// | sed s/" for"// | sed s/"pixels".*//  | tee Z.data

# remove .log
export filename="${filename%.log}"

# use -p if want plots to stay up
gnuplot plot.gp

convert -alpha off -density 300 \
    $filename".eps" -resize 1440x1080  -quality 90 $filename".jpg"    
    

filename="scffmpeg-"$run".log"
$EDRHOME/Tools/demos/sc/sigma_compare_PQ Frame834.exr F834_ffmpeg.exr | tee $filename
rm -fv *data


sed -n -e /"PQ Ave"/p -e /"#10k16b-"/p $filename | sed -n -e /sigma_red/p -e /"#10k16b-"/p | sed s/"#10k16b-".*//g | sed -e s/"pixels, PQ Ave".*//g | sed -e s/"sigma_red".// | sed -e s/"] ="// | sed -e s/"self_relative =".*"(".*" ="// | sed s/" for"// | sed s/"pixels".*//  | tee X.data

sed -n -e /"PQ Ave"/p -e /"#10k16b-"/p $filename | sed -n -e /sigma_grn/p -e /"#10k16b-"/p | sed s/"#10k16b-".*//g | sed -e s/"pixels, PQ Ave".*//g | sed -e s/"sigma_grn".// | sed -e s/"] ="// | sed -e s/"self_relative =".*"(".*" ="// | sed s/" for"// | sed s/"pixels".*//  | tee Y.data

sed -n -e /"PQ Ave"/p -e /"#10k16b-"/p $filename | sed -n -e /sigma_blu/p -e /"#10k16b-"/p | sed s/"#10k16b-".*//g | sed -e s/"pixels, PQ Ave".*//g | sed -e s/"sigma_blu".// | sed -e s/"] ="// | sed -e s/"self_relative =".*"(".*" ="// | sed s/" for"// | sed s/"pixels".*//  | tee Z.data

# remove .log
export filename="${filename%.log}"

# use -p if want plots to stay up
gnuplot plot.gp

convert -alpha off -density 300 \
    $filename".eps" -resize 1440x1080  -quality 90 $filename".jpg"      
    



filename="sc10bit.log"
$EDRHOME/Tools/demos/sc/sigma_compare_PQ Frame834.exr F834_10bit.exr | tee $filename
rm -fv *data


sed -n -e /"PQ Ave"/p -e /"#10k16b-"/p $filename | sed -n -e /sigma_red/p -e /"#10k16b-"/p | sed s/"#10k16b-".*//g | sed -e s/"pixels, PQ Ave".*//g | sed -e s/"sigma_red".// | sed -e s/"] ="// | sed -e s/"self_relative =".*"(".*" ="// | sed s/" for"// | sed s/"pixels".*//  | tee X.data

sed -n -e /"PQ Ave"/p -e /"#10k16b-"/p $filename | sed -n -e /sigma_grn/p -e /"#10k16b-"/p | sed s/"#10k16b-".*//g | sed -e s/"pixels, PQ Ave".*//g | sed -e s/"sigma_grn".// | sed -e s/"] ="// | sed -e s/"self_relative =".*"(".*" ="// | sed s/" for"// | sed s/"pixels".*//  | tee Y.data

sed -n -e /"PQ Ave"/p -e /"#10k16b-"/p $filename | sed -n -e /sigma_blu/p -e /"#10k16b-"/p | sed s/"#10k16b-".*//g | sed -e s/"pixels, PQ Ave".*//g | sed -e s/"sigma_blu".// | sed -e s/"] ="// | sed -e s/"self_relative =".*"(".*" ="// | sed s/" for"// | sed s/"pixels".*//  | tee Z.data

# remove .log
export filename="${filename%.log}"

# use -p if want plots to stay up
gnuplot plot.gp

convert -alpha off -density 300 \
    $filename".eps" -resize 1440x1080  -quality 90 $filename".jpg"      



filename="sc12bit.log"
$EDRHOME/Tools/demos/sc/sigma_compare_PQ Frame834.exr F834_12bit.exr | tee $filename
rm -fv *data


sed -n -e /"PQ Ave"/p -e /"#10k16b-"/p $filename | sed -n -e /sigma_red/p -e /"#10k16b-"/p | sed s/"#10k16b-".*//g | sed -e s/"pixels, PQ Ave".*//g | sed -e s/"sigma_red".// | sed -e s/"] ="// | sed -e s/"self_relative =".*"(".*" ="// | sed s/" for"// | sed s/"pixels".*//  | tee X.data

sed -n -e /"PQ Ave"/p -e /"#10k16b-"/p $filename | sed -n -e /sigma_grn/p -e /"#10k16b-"/p | sed s/"#10k16b-".*//g | sed -e s/"pixels, PQ Ave".*//g | sed -e s/"sigma_grn".// | sed -e s/"] ="// | sed -e s/"self_relative =".*"(".*" ="// | sed s/" for"// | sed s/"pixels".*//  | tee Y.data

sed -n -e /"PQ Ave"/p -e /"#10k16b-"/p $filename | sed -n -e /sigma_blu/p -e /"#10k16b-"/p | sed s/"#10k16b-".*//g | sed -e s/"pixels, PQ Ave".*//g | sed -e s/"sigma_blu".// | sed -e s/"] ="// | sed -e s/"self_relative =".*"(".*" ="// | sed s/" for"// | sed s/"pixels".*//  | tee Z.data

# remove .log
export filename="${filename%.log}"

# use -p if want plots to stay up
gnuplot plot.gp

convert -alpha off -density 300 \
    $filename".eps" -resize 1440x1080  -quality 90 $filename".jpg"  
    
}    



set -x


proresGIC="LS_10frames_HDR_rec2020_PQ_1000nit_ProRes4444XQ_2398p_GIC_VideoOnly_Test.mov"
proresSwitch="LS_5frames_HDR_rec2020_PQ_1000nit_ProRes4444XQ_24p_Switch162_VideoOnlyTest.mov"
proresFA="LS_10frames_HDR_rec2020_PQ_1000nit_ProRes4444XQ_24p_FlameAssist2106_VideoOnlyTest.mov"
f834="LS_R3_3840x2160_24Fps_16bit_rec2020_PQ_FullRange_1000nit_Master.0260226.tiff"


prores=$proresFA
run="FA"
FRAMETEST


prores=$proresGIC
run="GIC"
FRAMETEST


prores=$proresSwitch
run="Switch"
FRAMETEST








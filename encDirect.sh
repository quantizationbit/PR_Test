#!/bin/bash

set -x

YUVBASE="Direct1000"


# Encode
crf=12

(ffmpeg -y -i Lr_5minClip_HDR_UHD2160_240_ProRes4444_rec2020_PQ_1000nits_2398p_Clipster6Test.mov \
   -an  -pix_fmt yuv420p10le -f rawvideo -vcodec rawvideo - | x265 --input - \
   --input-depth 10 --input-res 3840x2160 --fps 23.98 \
   --profile main10 --level-idc 51 --no-high-tier --tune grain \
   --crf $crf --aq-mode 3  \
    -p slow  --bframes 12 -I 72 --sar 1 --range limited \
   --colorprim bt2020 --transfer 16 --colormatrix bt2020nc --chromaloc 2 \
   --master-display "G(13250,34500)B(7500,3000)R(34000,16000)WP(15635,16450)L(10000000,50)" \
   --max-cll "1000,400" \
   --repeat-headers  \
   -o x265-$YUVBASE-$crf.bin ) 2>&1 | tee logencoder-x265-$YUVBASE-$crf.txt






prores="Lr_5minClip_HDR_UHD2160_240_ProRes4444_rec2020_PQ_1000nits_2398p_Clipster6Test.mov"
 


## Audio
ffmpeg -y -i $prores -vn   \
       -filter_complex "[0:2][0:3][0:4][0:5][0:6][0:7]amerge=inputs=6[aout]" \
       -map "[aout]" \
       -ac 6  -acodec libfdk_aac -cutoff 18000 -ab 768k audio.aac





MP4Box -v -add x265-$YUVBASE-$crf".bin#0:FMT=HEVC:fps=23.98"   -add "audio.aac:lang=en" -hint -rap  -new x265-$YUVBASE-$crf"-24Hz-cloc2.mp4"



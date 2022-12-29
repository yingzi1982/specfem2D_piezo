#!/usr/bin/env bash
#module load gmt
source /pdc/software/21.11/eb/software/Anaconda3/2021.05/bin/activate
conda activate gmt6
#gmt defaults > gmt.conf
rm -f gmt.conf
rm -f gmt.history
#gmt set MAP_FRAME_TYPE plain
#gmt set MAP_FRAME_PEN thin
gmt set FONT 12p,Helvetica,black
#--------------------------------------------------------------------
#name=${1}
name=current
backupFolder=../backup/
#DATAFolder=../DATA/
figFolder=../figures/
mkdir -p $figFolder
fig=$figFolder$name\_specgram

originalxyz=$backupFolder$name\_specgram
grd=$backupFolder$name\_specgram\.nc

tscale=1E-9
fscale=1E9

tmin=`gmt info $originalxyz -C | awk -v tscale="$tscale" '{print $1/tscale}'`
tmax=`gmt info $originalxyz -C | awk -v tscale="$tscale" '{print $2/tscale}'`
fmin=`gmt info $originalxyz -C | awk -v fscale="$fscale" '{print $3/fscale}'`
fmax=`gmt info $originalxyz -C | awk -v fscale="$fscale" '{print $4/fscale}'`

tmin=0
tmax=20
fmin=0
fmax=4

width=2.2
height=0.8
#height=`echo "$width*(($zmax)-($zmin))/(($xmax)-($xmin))" | bc -l`
projection=X$width\i/$height\i
region=$tmin/$tmax/$fmin/$fmax

nt=400
nf=200

tinc=`echo "($tmax-$tmin)/$nt" | bc -l`
finc=`echo "($fmax-$fmin)/$nf" | bc -l`
inc=$tinc/$finc

#--------------------------------------------------------------------

amplitude_min=`gmt info $originalxyz -C | awk '{print $5}'`
amplitude_max=`gmt info $originalxyz -C | awk '{print $6}'`

specgramLowerLimit=-50
specgramUpperLimit=0


gmt begin $fig

gmt makecpt -CGMT_rainbow.cpt -T$specgramLowerLimit/$specgramUpperLimit

awk -v tscale="$tscale" -v fscale="$fscale" '{print $1/tscale, $2/fscale, $3}' $originalxyz | gmt blockmean -R$region -I$inc | gmt surface -Ll$specgramLowerLimit -Lu$specgramUpperLimit -R$region -I$inc -G$grd

gmt grdimage $grd -R$region -J$projection -BWeSn -Bx10f5+l"Time ($tscale\s)" -By2f1+l"Freq ($fscale\Hz)"

colorbar_width=$height
colorbar_height=0.16
colorbar_horizontal_position=`echo "$width+0.1" | bc -l`
colorbar_vertical_position=`echo "$colorbar_width/2" | bc -l`
domain=$colorbar_horizontal_position\i/$colorbar_vertical_position\i/$colorbar_width\i/$colorbar_height\i
gmt colorbar -Dx$domain -Bxa50f25 -By+l"dB/Hz"

#-----------------------------------------------------
xy=$backupFolder$name
ymin=`gmt gmtinfo $xy -C | awk '{print $3}'`
ymax=`gmt gmtinfo $xy -C | awk '{print $4}'`
normalization=`echo $ymin $ymax | awk ' { if(sqrt($1^2)>(sqrt($2^2))) {print sqrt($1^2)} else {print sqrt($2^2)}}'`

width2=$width
height2=0.2

projection=X$width2\i/$height2\i
region=$tmin/$tmax/-1/1

gmt gmtset MAP_FRAME_AXES wesn
YShift=`echo "($height-$height2)" | bc -l`

resample_rate=10
cat $xy | awk  -v tscale="$tscale" -v normalization="$normalization" -v resample_rate="$resample_rate" 'NR%resample_rate==0 {print $1/tscale, $2/normalization}' | gmt plot -R$region -J$projection -Y$YShift\i -Wthin,black

#-----------------------------------------------------
#
gmt end
#-----------------------------------------------------
rm -f $grd

rm -f gmt.conf
rm -f gmt.history
#module unload gmt
conda deactivate

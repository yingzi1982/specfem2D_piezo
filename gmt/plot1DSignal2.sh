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
name=${1}
resample_rate=${2}

xlabel=${3}
xscale=${4}
xunit=${5}
xrange=${6}
xtick=${7}

ylabel=${8}
yscale=${9}
yunit=${10}
yrange=${11}
ytick=${12}

backupFolder=../backup/
figFolder=../figures/
mkdir -p $figFolder
fig=$figFolder$name

originalxy=$backupFolder$name

xmin=`echo $xrange | awk '{print $1}'`
xmax=`echo $xrange | awk '{print $2}'`
ymin=`echo $yrange | awk '{print $1}'`
ymax=`echo $yrange | awk '{print $2}'`

region=$xmin/$xmax/$ymin/$ymax

width=2.2
height=1.8
projection=X$width\i/$height\i

gmt begin $fig

#label1='09pairs'
#label2='49pairs'
#label3='99pairs'

#label1="000nm"
#label2='200nm'
#label3='400nm'

awk -v xscale="$xscale" -v yscale="$yscale" -v resample_rate="$resample_rate" 'NR%resample_rate==0 {print $1/xscale, $2/yscale}' $originalxy | gmt plot -J$projection -R$region -Bx$xtick+l"$xlabel ($xscale$xunit)" -By$ytick+l"$ylabel ($yscale$yunit)" -Wthin,black -l'49 pairs'

#awk -v xscale="$xscale" -v yscale="$yscale" -v resample_rate="$resample_rate" 'NR%resample_rate==0 {print $1/xscale, $2/yscale}' $originalxy | gmt plot -J$projection -R$region -Bx$xtick+l"$xlabel ($xscale$xunit)" -By$ytick+l"$ylabel " -Wthin,red,. -l$label1
#awk -v xscale="$xscale" -v yscale="$yscale" -v resample_rate="$resample_rate" 'NR%resample_rate==0 {print $1/xscale, $3/yscale}' $originalxy | gmt plot -J$projection -R$region -Bx$xtick+l"$xlabel ($xscale$xunit)" -By$ytick+l"$ylabel " -Wthin,blue,- -l$label2
#awk -v xscale="$xscale" -v yscale="$yscale" -v resample_rate="$resample_rate" 'NR%resample_rate==0 {print $1/xscale, $4/yscale}' $originalxy | gmt plot -J$projection -R$region -Bx$xtick+l"$xlabel ($xscale$xunit)" -By$ytick+l"$ylabel " -Wthin,black -l$label3
#8.2827

#gmt legend -DjTR+o0.5c -F+pthick+ithinner+gwhite #--FONT_ANNOT_PRIMARY=18p,Times-Italic
gmt legend -DjTR --FONT_ANNOT_PRIMARY=8p #-F+pthick+ithinner+gwhite #--FONT_ANNOT_PRIMARY=18p,Times-Italic

gmt end

rm -f gmt.conf
rm -f gmt.history
#module unload gmt
conda deactivate

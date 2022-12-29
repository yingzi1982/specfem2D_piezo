#!/bin/bash

filter_dimension=$1

Par_file=../DATA/Par_file
Par_file_part=../backup/Par_file.part
cat $Par_file_part > $Par_file
source_file=../DATA/SOURCE
station_file=../DATA/STATIONS

nx=`grep nx ../backup/meshInformation | cut -d = -f 2`
#ny=`grep ny ../backup/meshInformation | cut -d = -f 2`
nz=`grep nz ../backup/meshInformation | cut -d = -f 2`

echo "nbmodels                        = 1" >> $Par_file
echo "1 2 4650 2.03e+11 7.52e+10 0 2.424e+11 0 5.95e+10 5.73e+10 7.52e+10 0 0 0 0" >> $Par_file
echo "nbregions                       = 1" >> $Par_file
echo "1 $nx 1  $nz  1" >> $Par_file

oldString=`grep "^NPROC " $Par_file`
newString='NPROC                           = 1'
sed -i "s/$oldString/$newString/g" $Par_file

oldString=`grep "^NSTEP " $Par_file`
newString='NSTEP                              = 10'
sed -i "s/$oldString/$newString/g" $Par_file

oldString=`grep "^use_existing_STATIONS " $Par_file`
newString='use_existing_STATIONS           = .true.'
sed -i "s/$oldString/$newString/g" $Par_file
rm -f $station_file
touch $station_file
echo "S1 A 0 0 0 0" >> $station_file

#f0=`grep ^ATTENUATION_f0_REFERENCE ../backup/Par_file.part | cut -d = -f 2`
#oldString=`grep "^NSOURCES " $Par_file`
#newString='NSOURCES                        = 1'
#sed -i "s/$oldString/$newString/g" $Par_file
#rm -f $source_file
#touch $source_file
#echo "source_surf        = .false." >> $source_file
#echo "xs                 = 0.0" >> $source_file
#echo "zs                 = 0.0" >> $source_file
#echo "source_type        = 1" >> $source_file
#echo "time_function_type = 1" >> $source_file
#echo "name_of_source_file= DATA/STF" >> $source_file
#echo "burst_band_width   = 0.0" >> $source_file
#echo "f0                 = $f0" >> $source_file
#echo "tshift             = 0.0" >> $source_file
#echo "anglesource        = 0.0" >> $source_file
#echo "Mxx                = 1.0" >> $source_file
#echo "Mzz                = 1.0" >> $source_file
#echo "Mxz                = 0.0" >> $source_file
#echo "factor             = 1.0" >> $source_file
#echo "vx                 = 0.0" >> $source_file
#echo "vz                 = 0.0" >> $source_file

oldString=`grep "^SAVE_MODEL " $Par_file`
newString='SAVE_MODEL                      = ascii'
sed -i "s/$oldString/$newString/g" $Par_file

./specfem.sh $filter_dimension

#mv ./DATA/proc000000_rho_vp_vs.dat ./backup/proc000000_rho_vp_vs.dat.serial

#!/bin/bash

filter_type=$1
filter_dimension=$2

station_file=../DATA/STATIONS

rm -f ../backup/STATIONS_*
rm -f $station_file

./octave.sh generate_stations.m  $filter_type $filter_dimension

touch $station_file

[ -f ../backup/STATIONS_PF ] && cat ../backup/STATIONS_PF >> $station_file
[ -f ../backup/STATIONS_PF2 ] && cat ../backup/STATIONS_PF2 >> $station_file 

[ -f ../backup/STATIONS_NF ] && cat ../backup/STATIONS_NF >> $station_file
[ -f ../backup/STATIONS_NF2 ] && cat ../backup/STATIONS_NF2 >> $station_file 

[ -f ../backup/STATIONS_LA ] && cat ../backup/STATIONS_LA >> $station_file
[ -f ../backup/STATIONS_LA2 ] && cat ../backup/STATIONS_LA2 >> $station_file

[ -f ../backup/STATIONS_SA ] && cat ../backup/STATIONS_SA >> $station_file

rm -f ../backup/STATIONS_*

#!/bin/bash


Par_file=../DATA/Par_file
Par_file_part=../backup/Par_file.part
cat $Par_file_part > $Par_file

cat ../backup/nbmodels >> $Par_file
cat ../backup/models >> $Par_file
cat ../backup/nbregions >> $Par_file
paste -d " " ../backup/regions ../backup/regionsMaterialNumbering >> $Par_file

rm -f ../backup/nbmodels ../backup/models ../backup/nbregions ../backup/regions ../backup/regionsMaterialNumbering

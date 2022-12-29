#!/bin/bash

filter_type=$1
filter_dimension=$2

cp ../backup/Par_file.part_$filter_type\_$filter_dimension ../backup/Par_file.part
oldString=`grep ^title ../backup/Par_file.part`
newString="title                           = $filter_type$filter_dimension"
sed -i "s/$oldString/$newString/g" ../backup/Par_file.part

./create_model.sh $filter_type $filter_dimension

./create_converse_piezoelectricity.sh $filter_type $filter_dimension

./create_sources.sh $filter_dimension

./create_stations.sh  $filter_type $filter_dimension

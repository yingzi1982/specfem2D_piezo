#!/bin/bash

filter_type=$1
filter_dimension=$2

backup_folder=../backup/$filter_type$filter_dimension
mkdir $backup_folder

cd ../backup/
cp LA_trace_image SA_coordinate SA_snapshots_* snapshot_time $backup_folder
cd -

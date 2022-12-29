#!/bin/bash

filter_type=$1
filter_dimension=$2

./process_traces.sh $filter_type $filter_dimension

#./backup_data.sh $filter_type $filter_dimension

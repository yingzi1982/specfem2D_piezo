#!/bin/bash

filter_type=$1
filter_dimension=$2

./process_traces.sh $filter_type $filter_dimension

./octave.sh process_charge_signal.m

#./backup_data.sh $filter_type $filter_dimension

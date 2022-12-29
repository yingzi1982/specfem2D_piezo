#!/bin/bash

filter_type=$1
filter_dimension=$2

./octave.sh process_traces.m $filter_type $filter_dimension

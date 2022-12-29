#!/bin/bash
filter_type=$1
filter_dimension=$2

./octave.sh generate_electricFields.m $filter_type $filter_dimension

mv ../backup/CHARGES ../DATA/CHARGES

./octave.sh generate_converse_piezoelectricity.m $filter_dimension


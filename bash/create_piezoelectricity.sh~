#!/bin/bash
filter_type=$1
filter_dimension=$2
piezoelectric_effect=$3

if [ $piezoelectric_effect == 'converse' ]
then

./octave.sh generate_electrodeContactSurface.m $filter_type $filter_dimension
./octave.sh generate_electricFields.m $filter_type $filter_dimension

elif [ $piezoelectric_effect == 'direct' ]
then
echo ' '
fi

./octave.sh generate_piezoelectricity.m $piezoelectric_effect $filter_dimension

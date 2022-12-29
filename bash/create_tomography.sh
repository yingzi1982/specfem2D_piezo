#!/bin/bash
filter_dimension=$1

#./create_mesh_coordinates.sh $filter_dimension

#./create_mesh_coordinates_regular_grid.sh

./octave.sh generate_tomography.m $filter_dimension

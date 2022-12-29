#!/bin/bash

code_type=$1

if [ $code_type == 'original' ]
then
echo 'copying the original code...'
cp -rf ../fortran/original/src/ ../../../
cp -rf ../fortran/original/Makefile.in ../../../
elif [ $code_type == 'modified' ]
then
echo 'copying the modified code...'
cp -rf ../fortran/modified/piezo/ ../../../src/
cp -rf ../fortran/modified/Makefile.in ../../../
cp -rf ../fortran/modified/specfem2D/rules.mk ../../../src/specfem2D/
cp -rf ../fortran/modified/specfem2D/initialize_simulation.F90 ../../../src/specfem2D/
fi

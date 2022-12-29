#!/bin/bash

folder=$1

srcDir=../fortran/$folder/

destDir=../../../src/specfem2D/

for file in prepare_source_time_function.f90 compute_add_sources_viscoelastic.f90 read_save_binary_database.f90
do
  cp $srcDir$file  $destDir$file
  echo copied $file from $folder
done

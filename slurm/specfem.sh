#!/bin/bash -l
#SBATCH -A snic2022-22-620 #pdc-test-2022 #
#SBATCH -p main #main long shared memory
#SBATCH -J specfem
#SBATCH -t 1:00:00
#SBATCH -o output.txt
#SBATCH -e error.txt
#SBATCH -N 1
#SBATCH --mail-user=yingzi.ying@me.com
#SBATCH --mail-type=ALL

#cd $SLURM_SUBMIT_DIR

filter_type=SAW
filter_dimension=2D

cd ../bash
./preprocess.sh $filter_type $filter_dimension
./specfem.sh $filter_dimension
./postprocess.sh $filter_type $filter_dimension

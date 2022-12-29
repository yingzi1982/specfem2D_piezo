#!/bin/bash 

#SBATCH -A pdc-test-2022 #
#SBATCH -p shared #main long shared memory
#SBATCH -c 1
#SBATCH -J processing
#SBATCH -t 5:00:00
#SBATCH -o output.txt
#SBATCH -e error.txt
#SBATCH --mail-user=yingzi.ying@me.com
#SBATCH --mail-type=ALL

#cd $SLURM_SUBMIT_DIR

filter_type=SAW
filter_dimension=2D

cd ../bash
#./preprocess.sh $filter_type $filter_dimension
#./specfem.sh $filter_dimension
./postprocess.sh $filter_type $filter_dimension

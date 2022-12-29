#!/bin/bash
#module load PDC octave/6.3.0
#module load PDC intel-oneapi gnuplot octave
source /pdc/software/21.11/eb/software/Anaconda3/2021.05/bin/activate
conda activate octave7

octave_script=$1
input_parameters=$2
input_parameters2=$3

cd ../octave

./$octave_script $input_parameters $input_parameters2

conda deactivate
#module unload PDC octave/6.3.0
#module unload PDC intel-oneapi gnuplot octave

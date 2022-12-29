#!/bin/bash
#module load git
operation=$1
folder="../README.md ../bash/*sh ../figures/*pdf ../gmt/*cpt ../gmt/*sh ../octave/*m ../fortran/modified/ ../slurm/*sh ../backup/Par_file.part_SAW_2D"
#folder="../README.md"
#../backup/* 

#folder=$2

if [ $operation == 'push' ]
then
git add $folder
git commit -m "pushing to Github"
git push -u origin main
elif [ $operation == 'pull' ]
then
git commit -m "pulling from Github"
git pull origin main
fi

#module unload git
cd -

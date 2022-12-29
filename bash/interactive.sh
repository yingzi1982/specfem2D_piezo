#!/bin/bash
#project=pdc-test-2022
project=snic2022-22-620
partition=shared #main long shared memory
#srun -N 1 -t 1:00:00 -A $project -p $partition --pty bash -i
#salloc -N 1 -t 1:00:00 -A $project -p $partition
srun -c 1 -t 10:00:00 -A $project -p $partition --pty bash -i

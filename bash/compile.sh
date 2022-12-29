#!/bin/bash
#module load PrgEnv-cray

code_type=modified #modified #original
./update_source_code.sh $code_type

currentdir=`pwd`
cd ../../../
# configure
#echo ">>configuring"
#./configure MPI_INC="${CRAY_MPICH2_DIR}/include" --with-mpi MPIFC=ftn MPICC=ccc FC=ftn CC=cc CXX=cc #> configure.log
#
#make clean > making.log
make piezo > making.log

# make
#make clean > making.log
#echo "made clean" 
#make xmeshfem2D >> making.log
#echo "made xmeshfem2D"
make xspecfem2D >> making.log
echo "made xspecfem2D"

# link
echo ">>coping executables"
cd $currentdir
#cp -f ../../../bin/xmeshfem2D ../bin
#echo "linked xmeshfem2D"
cp -f ../../../bin/xspecfem2D ../bin
echo "linked xspecfem2D"

#module unload PrgEnv-cray

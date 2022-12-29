#!/bin/bash

FC=ftn 

rm -f *.mod *.o

#cd ../../../../../
#make shared
#make meshfem2D
#make specfem2D

#$FC -c shared_par.F90 constants.h
#
#$FC -c specfem2D_par.f90
#
#$FC -c parallel.F90
#
#$FC -c exit_mpi.F90
#
#$FC -c piezo_par.F90 
#
#$FC -c read_charges.f90
#
#$FC -c run.f90 

O=../../../../../obj

SHARED_OBJECTS=\
        $O/shared_par.shared_module.o \
        $O/define_shape_functions.shared.o \
        $O/exit_mpi.shared.o \
        $O/force_ftz.cc.o \
        $O/gll_library.shared.o \
        $O/lagrange_poly.shared.o \
        $O/parallel.sharedmpi.o \
        $O/read_parameter_file.shared.o \
        $O/read_value_parameters.shared.o \
        $O/read_material_table.shared.o \
        $O/read_interfaces_file.shared.o \
        $O/read_regions.shared.o \
        $O/read_source_file.shared.o \
        $O/param_reader.cc.o \
        $O/set_color_palette.shared.o \
        #$(EMPTY_MACRO)

exit

$FC -o run run.o $SHARED_OBJECTS
exit

rm -f *.mod *.o
exit

mv run ../../../
cd ../../../
./run
rm -f run
cd -
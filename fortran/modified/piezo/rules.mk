#========================================================================
#
#                   S P E C F E M 2 D  Version 7 . 0
#                   --------------------------------
#
#     Main historical authors: Dimitri Komatitsch and Jeroen Tromp
#                        Princeton University, USA
#                and CNRS / University of Marseille, France
#                 (there are currently many more authors!)
# (c) Princeton University and CNRS / University of Marseille, April 2014
#
# This software is a computer program whose purpose is to solve
# the two-dimensional viscoelastic anisotropic or poroelastic wave equation
# using a spectral-element method (SEM).
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with this program; if not, write to the Free Software Foundation, Inc.,
# 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
#
# The full text of the license is available in file "LICENSE".
#
#========================================================================

## compilation directories
S := ${S_TOP}/src/piezo
$(piezo_OBJECTS): S = ${S_TOP}/src/piezo

#######################################

piezo_TARGETS = \
	$(piezo_OBJECTS) \
	$(EMPTY_MACRO)


piezo_OBJECTS = \
	$O/piezo_par.piezo_module.o \
	$O/test.piezo.o \
	$O/read_charges.piezo.o \
	$(EMPTY_MACRO)


piezo_MODULES = \
	$(FC_MODDIR)/piezo_parameters.$(FC_MODEXT) \
	$(EMPTY_MACRO)


#######################################

####
#### rule for each .o file below
####


##
## piezo
##

$O/%.piezo_module.o: $S/%.F90 ${SETUP}/constants.h
	${FCCOMPILE_CHECK} ${FCFLAGS_f90} -c -o $@ $<

$O/%.piezo.o: $S/%.f90 ${SETUP}/constants.h $O/piezo_par.piezo_module.o
	${FCCOMPILE_CHECK} ${FCFLAGS_f90} -c -o $@ $<

$O/%.piezo.o: $S/%.F90 ${SETUP}/constants.h $O/piezo_par.piezo_module.o
	${FCCOMPILE_CHECK} ${FCFLAGS_f90} -c -o $@ $<

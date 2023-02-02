!========================================================================
!
!                   S P E C F E M 2 D ** PIEZO
!                   --------------------------------
!
!                     Author: Yingzi Ying
!                     yingzi.ying@me.com
!
!========================================================================

subroutine read_voltage_time_function()

use constants, only: IIN, IMAIN, CUSTOM_REAL, IN_DATA_FILES, MAX_STRING_LEN
use specfem_par
use mpi
use piezo_par, only: voltage_time_function

implicit none

character(len=MAX_STRING_LEN) :: voltage_time_function_filename

real(kind=CUSTOM_REAL) :: dummy_t

integer :: ier
integer :: i_time

voltage_time_function_filename = trim(IN_DATA_FILES)//'VTF'

allocate(voltage_time_function(NSTEP), stat=ier)
if (ier /= 0) call exit_MPI(myrank,'Error allocating voltage time function array.')

open(unit=IIN,file=trim(voltage_time_function_filename),status='old',action='read',iostat=ier)
if (ier /= 0) call exit_MPI(myrank,'No file '//trim(voltage_time_function_filename)//', exit')
do i_time = 1,NSTEP
  read(IIN,*,iostat=ier) dummy_t, voltage_time_function(i_time)
  if (ier /= 0) call exit_MPI(myrank,'Error reading voltage time function file.')
enddo
close(IIN)

endsubroutine
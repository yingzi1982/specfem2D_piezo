!========================================================================
!
!                   S P E C F E M 2 D ** PIEZO
!                   --------------------------------
!
!                     Author: Yingzi Ying
!                     yingzi.ying@me.com
!
!========================================================================

subroutine read_charges()

use constants, only: IIN, IMAIN, CUSTOM_REAL, IN_DATA_FILES, MAX_STRING_LEN
use specfem_par
use mpi
use piezo_par, only: charges, charge_number

implicit none

character(len=MAX_STRING_LEN) :: dummystring
character(len=MAX_STRING_LEN) :: charges_filename

integer :: ier
integer :: i_charge

charges_filename = trim(IN_DATA_FILES)//'CHARGES'
open(unit=IIN,file=trim(charges_filename),status='old',action='read',iostat=ier)
if (ier /= 0) call exit_MPI(myrank,'No file '//trim(charges_filename)//', exit')

charge_number = 0
do while(ier == 0)
  read(IIN,"(a)",iostat=ier) dummystring
  if (ier == 0) charge_number = charge_number + 1
enddo
close(IIN)

write(IMAIN,*) 'The total charge number is: ', charge_number

allocate(charges(charge_number,3), stat=ier)
if (ier /= 0) call exit_MPI(myrank,'Error allocating charge array.')

open(unit=IIN,file=trim(charges_filename),status='old',action='read',iostat=ier)
if (ier /= 0) call exit_MPI(myrank,'No file '//trim(charges_filename)//', exit')
do i_charge = 1,charge_number
  read(IIN,*,iostat=ier) charges(i_charge,1), charges(i_charge,2), charges(i_charge,3)
  if (ier /= 0) call exit_MPI(myrank,'Error reading charge file.')
enddo
close(IIN)

!write(IMAIN,*) 'The shape of charge is: ', shape(charges) 
end subroutine

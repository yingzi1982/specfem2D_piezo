!========================================================================
!
!                   S P E C F E M 2 D  PIEZO
!                   --------------------------------
!
!                     Author: Yingzi Ying
!                     yingzi.ying@me.com
!
! This software is a computer program whose purpose is to solve
! the two-dimensional viscoelastic anisotropic or poroelastic wave equation
! using a spectral-element method (SEM).
!
! This program is free software; you can redistribute it and/or modify
! it under the terms of the GNU General Public License as published by
! the Free Software Foundation; either version 3 of the License, or
! (at your option) any later version.
!
! This program is distributed in the hope that it will be useful,
! but WITHOUT ANY WARRANTY; without even the implied warranty of
! MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
! GNU General Public License for more details.
!
! You should have received a copy of the GNU General Public License along
! with this program; if not, write to the Free Software Foundation, Inc.,
! 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
!
! The full text of the license is available in file "LICENSE".
!
!========================================================================

  subroutine read_charges()

  use constants, only: IIN, IMAIN, CUSTOM_REAL, IN_DATA_FILES, MAX_STRING_LEN
  use piezo_par, only: is_piezo
  use specfem_par
  use mpi

  implicit none

  character(len=MAX_STRING_LEN) :: dummystring
  character(len=MAX_STRING_LEN) :: charges_filename
  integer :: ier
  integer :: ncharge


  charges_filename = trim(IN_DATA_FILES)//'CHARGES'
  open(unit=IIN,file=trim(charges_filename),status='old',action='read',iostat=ier)
  !if (ier /= 0) call exit_MPI(myrank,'No file '//trim(charges_filename)//', exit')

  ncharge = 0
  do while(ier == 0)
    read(IIN,"(a)",iostat=ier) dummystring
    if (ier == 0) ncharge = ncharge + 1
  enddo
  close(IIN)

  write(IMAIN,*) 'The total charge number is: ', ncharge

  !allocate(xi_source(NSOURCES), &
           !gamma_source(NSOURCES),stat=ier)
  !if (ier /= 0) call stop_the_code('Error allocating source arrays')


  end subroutine read_charges

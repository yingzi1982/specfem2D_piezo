!========================================================================
!
!                   S P E C F E M 2 D ** PIEZO
!                   --------------------------------
!
!                     Author: Yingzi Ying
!                     yingzi.ying@me.com
!
!========================================================================

subroutine calculate_piezo_stress(receiver_position, piezo_stress)

use piezo_par, only : vacuum_permittivity, piezoelectric_constant_2d, charges, charge_number 

use constants, only : PI
use constants, only : myrank, IMAIN, CUSTOM_REAL


implicit none

real(kind=CUSTOM_REAL), dimension(2), intent(in) :: receiver_position
real(kind=CUSTOM_REAL), dimension(3), intent(out) :: piezo_stress 

real(kind=CUSTOM_REAL) :: charge_value
real(kind=CUSTOM_REAL), dimension(2) :: charge_position

real(kind=CUSTOM_REAL), dimension(2) :: electric

integer :: i_charge

integer :: ii,jj

electric(:) = 0.0_CUSTOM_REAL
piezo_stress(:) = 0.0_CUSTOM_REAL

!charge_value = 0.0_CUSTOM_REAL
!charge_position(:) = 0.0_CUSTOM_REAL
!write(IMAIN,*) ((charges(ii,jj)," ",jj=1,size(charges,dim=2)), new_line("A"), ii=1,size(charges,dim=1))

do i_charge = 1,charge_number
  charge_position = charges(i_charge,1:2)
  charge_value = charges(i_charge,3)
  electric = electric + charge_value/(4.0_CUSTOM_REAL*PI*vacuum_permittivity)/((norm2(receiver_position - charge_position))**3.0_CUSTOM_REAL)*(receiver_position - charge_position)
end do

piezo_stress = -matmul(transpose(piezoelectric_constant_2d),electric)
write(IMAIN,*) 'print electric', electric(1), electric(2)
write(IMAIN,*) 'print piezo stress', piezo_stress(1), piezo_stress(2), piezo_stress(3)
!'(e16.6)'
!'(e10.3)'
!'(e10.3)'
end subroutine

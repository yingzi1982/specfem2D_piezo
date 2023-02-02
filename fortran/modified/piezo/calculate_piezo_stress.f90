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

implicit none


double precision, dimension(2), intent(in) :: receiver_position
double precision, dimension(3), intent(out) :: piezo_stress 

double precision :: charge_value
double precision, dimension(2) :: charge_position

double precision, dimension(2) :: electric

integer :: i_charge

electric(:) = 0.0d0
piezo_stress(:) = 0.0d0

do i_charge = 1,charge_number
  charge_value = charges(i_charge,1)
  charge_position = charges(i_charge,2:3)
  electric = electric + charge_value/(4.0d0*PI*vacuum_permittivity)/((norm2(receiver_position - charge_position))**3.0d0)*(receiver_position - charge_position)
end do

piezo_stress = -matmul(transpose(piezoelectric_constant_2d),electric)

end subroutine

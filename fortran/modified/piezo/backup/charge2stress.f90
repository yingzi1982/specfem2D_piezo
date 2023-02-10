!========================================================================
!
!                   S P E C F E M 2 D ** PIEZO
!                   --------------------------------
!
!                     Author: Yingzi Ying
!                     yingzi.ying@me.com
!
!========================================================================

function charge2stress(charge,receiver_position)

use piezo_par, only : vacuum_permittivity, piezoelectric_constant_2d
use constants, only : PI

implicit none

double precision, dimension(3) :: charge2stress
double precision, dimension(2) :: electric

double precision, dimension(3), intent(in) :: charge
double precision, dimension(2), intent(in) :: receiver_position

electric = charge(1)/(4.0d0*PI*vacuum_permittivity)/((norm2(receiver_position - charge(2:3)))**3.0d0)*(receiver_position - charge(2:3))

charge2stress = -matmul(transpose(piezoelectric_constant_2d),electric)

end function
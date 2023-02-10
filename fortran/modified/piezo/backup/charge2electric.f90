!========================================================================
!
!                   S P E C F E M 2 D ** PIEZO
!                   --------------------------------
!
!                     Author: Yingzi Ying
!                     yingzi.ying@me.com
!
!========================================================================

function charge2electric(charge,source_position,receiver_position) result(electric)

use piezo_par, only : vacuum_permittivity
use constants, only : PI

implicit none

double precision, dimension(2) :: electric

double precision, intent(in) :: charge
double precision, dimension(2), intent(in) :: source_position,receiver_position

electric = charge/(4.0d0*PI*vacuum_permittivity)/((norm2(receiver_position - source_position))**3.0d0)*(receiver_position - source_position)

end function

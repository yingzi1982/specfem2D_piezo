!========================================================================
!
!                   S P E C F E M 2 D ** PIEZO
!                   --------------------------------
!
!                     Author: Yingzi Ying
!                     yingzi.ying@me.com
!
!========================================================================

function electric2stress(electric) result(stress)

use piezo_par, only : piezoelectric_constant_2d

implicit none

double precision, dimension(3) :: stress

double precision, dimension(2), intent(in) :: electric

stress = -matmul(transpose(piezoelectric_constant_2d),electric)

end function

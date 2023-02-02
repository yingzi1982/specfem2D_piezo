!========================================================================
!
!                   S P E C F E M 2 D ** PIEZO
!                   --------------------------------
!
!                     Author: Yingzi Ying
!                     yingzi.ying@me.com
!
!========================================================================

subroutine finalize_piezo()

use piezo_par, only: voltage_time_function, charges

implicit none

deallocate(voltage_time_function)
deallocate(charges)

end subroutine

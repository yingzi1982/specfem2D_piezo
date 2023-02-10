!========================================================================
!
!                   S P E C F E M 2 D ** PIEZO
!                   --------------------------------
!
!                     Author: Yingzi Ying
!                     yingzi.ying@me.com
!
!========================================================================

module piezo_par

use constants, only: CUSTOM_REAL

implicit none

logical, parameter :: is_piezo = .true.

real(kind=CUSTOM_REAL), dimension(:,:), allocatable :: charges

real(kind=CUSTOM_REAL), dimension(:), allocatable :: voltage_time_function

integer :: charge_number

real(kind=CUSTOM_REAL), parameter :: vacuum_permittivity = 8.55e-12

real(kind=CUSTOM_REAL), parameter, dimension(3,6) :: piezoelectric_constant_3d = reshape(&
[0.0_CUSTOM_REAL, 0.0_CUSTOM_REAL, 0.0_CUSTOM_REAL, 0.0_CUSTOM_REAL, 3.83_CUSTOM_REAL, -2.37_CUSTOM_REAL,&
-2.37_CUSTOM_REAL, 2.37_CUSTOM_REAL, 0.0_CUSTOM_REAL, 3.83_CUSTOM_REAL, 0.0_CUSTOM_REAL, 0.0_CUSTOM_REAL,&
0.23_CUSTOM_REAL, 0.23_CUSTOM_REAL, 1.3_CUSTOM_REAL, 0.0_CUSTOM_REAL, 0.0_CUSTOM_REAL, 0.0_CUSTOM_REAL  ], shape(piezoelectric_constant_3d), order=[2,1])

real(kind=CUSTOM_REAL), parameter, dimension(2,3) :: piezoelectric_constant_2d = piezoelectric_constant_3d([1,3],[1,3,5])

end module piezo_par


!
!========================================================================
!

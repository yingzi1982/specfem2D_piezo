!========================================================================
!
!                   S P E C F E M 2 D ** PIEZO
!                   --------------------------------
!
!                     Author: Yingzi Ying
!                     yingzi.ying@me.com
!
!========================================================================

subroutine calculate_piezo_stress(dummy_coord_x,dummy_coord_z,dummy_sigma_xx,dummy_sigma_zz,dummy_sigma_xz,dummy_sigma_zx)

use piezo_par, only : vacuum_permittivity, piezoelectric_constant_2d, charges, charge_number 

use constants, only : PI

use constants, only : myrank, IMAIN, CUSTOM_REAL


implicit none


real(kind=CUSTOM_REAL), intent(in) :: dummy_coord_x, dummy_coord_z

real(kind=CUSTOM_REAL), intent(out) :: dummy_sigma_xx, dummy_sigma_zz, dummy_sigma_xz, dummy_sigma_zx

real(kind=CUSTOM_REAL) :: charge_value

real(kind=CUSTOM_REAL), dimension(2) :: charge_position

real(kind=CUSTOM_REAL), dimension(2) :: electric
real(kind=CUSTOM_REAL), dimension(2) :: total_electric

real(kind=CUSTOM_REAL), dimension(2) :: displacement

real(kind=CUSTOM_REAL), dimension(3) :: dummy_sigma
real(kind=CUSTOM_REAL), dimension(2) :: dummy_coord

integer :: i_charge

total_electric(:) = 0._CUSTOM_REAL
do i_charge = 1,charge_number
  charge_position = charges(i_charge,1:2)
  charge_value = charges(i_charge,3)
  dummy_coord = [dummy_coord_x,dummy_coord_z]
  displacement = dummy_coord - charge_position
  electric = -charge_value*displacement/(norm2(displacement)**2)
  total_electric = total_electric + electric
end do

dummy_sigma = -matmul(transpose(piezoelectric_constant_2d),electric)

dummy_sigma_xx = dummy_sigma(1)
dummy_sigma_zz = dummy_sigma(2)
dummy_sigma_xz = dummy_sigma(3)
dummy_sigma_zx = dummy_sigma_xz
end subroutine

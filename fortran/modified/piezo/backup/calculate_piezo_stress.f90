!========================================================================
!
!                   S P E C F E M 2 D ** PIEZO
!                   --------------------------------
!
!                     Author: Yingzi Ying
!                     yingzi.ying@me.com
!
!========================================================================

function piezo_stress(receiver_position)

use piezo_par, only : vacuum_permittivity, piezoelectric_constant_2d, charges, charge_number 

use constants, only : PI
use constants, only : myrank, IMAIN, CUSTOM_REAL


implicit none
!real(kind=CUSTOM_REAL)
double precision, dimension(2), intent(in) :: receiver_position
double precision, dimension(3), intent(out) :: piezo_stress 

double precision :: charge_value
double precision, dimension(2) :: charge_position

double precision, dimension(2) :: electric

double precision, dimension(2) :: diff

integer :: i_charge

integer :: ii,jj

electric(:) = 0.0

write(IMAIN,*) receiver_position(1), receiver_position(2)
!write(IMAIN,*) 'charges',shape(charges)
!write(IMAIN,*) ((charges(ii,jj)," ",jj=1,size(charges,dim=2)), new_line("A"), ii=1,size(charges,dim=1))

!write(IMAIN,*) 'charges'
!do i_charge = 1,charge_number
!write(IMAIn,*) i_charge, charges(i_charge,1), charges(i_charge,2), charges(i_charge,3)
!enddo

do i_charge = 1,charge_number
  charge_position = charges(i_charge,1:2)
  charge_value = charges(i_charge,3)
  diff = receiver_position - charge_position
  electric = electric + (-charge_value*diff/(norm2(diff)**2))
  
  !write(IMAIN,*) i_charge, receiver_position(1), receiver_position(2)
  !write(IMAIN,*) 'receiver', receiver_position(1), receiver_position(2)
  !write(IMAIN,*) 'charge', charge_position(1), charge_position(2), charge_value
  !write(IMAIN,*) 'diff', diff(1), diff(2), norm2(diff)
  !write(IMAIN,*) 'electric', electric(1), electric(2), norm2(electric)
  !call flush_IMAIN()
end do

!write(IMAIN,*) 'electric2', electric(1), electric(2), norm2(electric)
!call flush_IMAIN()

piezo_stress = -matmul(transpose(piezoelectric_constant_2d),electric)
!write(IMAIN,*) 'print piezo stress', piezo_stress(1), piezo_stress(2), piezo_stress(3)
end subroutine

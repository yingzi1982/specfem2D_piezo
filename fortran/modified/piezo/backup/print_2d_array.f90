!========================================================================
!
!                   S P E C F E M 2 D ** PIEZO
!                   --------------------------------
!
!                     Author: Yingzi Ying
!                     yingzi.ying@me.com
!
!========================================================================

subroutine print_2d_array(M)

use constants, only : IMAIN

implicit none

double precision, intent(in), dimension(:,:) :: M

integer :: i, j
integer :: row_number, column_number

row_number = size(M,dim=1)
column_number = size(M,dim=2)

write(IMAIN,*) 'Printing 2D matrix...'
write(IMAIN,*) 'NR = ', row_number,'NC = ',column_number

write(IMAIN,*) ((M(i,j)," ",j=1,column_number), new_line("A"), i=1,row_number)

end subroutine

!integer :: ii, jj 
!write(IMAIN,*) ((electric(ii,jj)," ",jj=1,size(piezoelectric_constant_2d,dim=2)), new_line("A"), ii=1,size(piezoelectric_constant_2d,dim=1))

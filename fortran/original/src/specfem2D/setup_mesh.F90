!========================================================================
!
!                   S P E C F E M 2 D  Version 7 . 0
!                   --------------------------------
!
!     Main historical authors: Dimitri Komatitsch and Jeroen Tromp
!                              CNRS, France
!                       and Princeton University, USA
!                 (there are currently many more authors!)
!                           (c) October 2017
!
! This software is a computer program whose purpose is to solve
! the two-dimensional viscoelastic anisotropic or poroelastic wave equation
! using a spectral-element method (SEM).
!
! This program is free software; you can redistribute it and/or modify
! it under the terms of the GNU General Public License as published by
! the Free Software Foundation; either version 3 of the License, or
! (at your option) any later version.
!
! This program is distributed in the hope that it will be useful,
! but WITHOUT ANY WARRANTY; without even the implied warranty of
! MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
! GNU General Public License for more details.
!
! You should have received a copy of the GNU General Public License along
! with this program; if not, write to the Free Software Foundation, Inc.,
! 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
!
! The full text of the license is available in file "LICENSE".
!
!========================================================================

  subroutine setup_mesh()

! creates mesh related properties, local to global mesh numbering and node locations

  use constants, only: IMAIN
  use specfem_par

  implicit none

  ! checks if anything to do
  if (setup_with_binary_database == 2) return

  ! user output
  if (myrank == 0) then
    write(IMAIN,*)
    write(IMAIN,*) 'Setting up mesh'
    call flush_IMAIN()
  endif

  ! generate the global numbering
  call setup_mesh_numbering()

  ! sets point coordinates
  call setup_mesh_coordinates()

  ! sets material properties on node points
  call setup_mesh_properties()

  ! for periodic edges
  call setup_mesh_periodic_edges()

  ! for acoustic forcing
  call setup_mesh_acoustic_forcing_edges()

  ! reads in external models and re-assigns material properties
  call setup_mesh_material_properties()

  ! checks domain flags
  call setup_mesh_basic_check()

  ! sets domain flags
  call setup_mesh_domains()

  ! sets up domain coupling, i.e. edge detection for domain coupling
  call get_coupling_edges()

  ! sets up MPI arrays and interfaces
  call get_MPI()

  ! user output
  if (myrank == 0) then
    write(IMAIN,*) 'All mesh setup done successfully'
    call flush_IMAIN()
  endif

  ! synchronizes all processes
  call synchronize_all()

  end subroutine setup_mesh

!
!-----------------------------------------------------------------------------------
!

  subroutine setup_mesh_numbering()

  use constants, only: IMAIN,FAST_NUMBERING
  use specfem_par

  implicit none

  ! local parameters
  integer :: ier
  ! to count the number of degrees of freedom
  integer :: nspec_acoustic_total,nspec_total,nglob_total
  integer :: nb_acoustic_DOFs,nb_elastic_DOFs
  double precision :: ratio_1DOF,ratio_2DOFs

  ! "slow and clean" or "quick and dirty" version
  if (FAST_NUMBERING) then
    call createnum_fast()
  else
    call createnum_slow()
  endif

  ! gets total numbers for all slices
  call sum_all_i(nspec_acoustic,nspec_acoustic_total)
  call sum_all_i(nspec,nspec_total)
  call sum_all_i(nglob,nglob_total)

  if (myrank == 0) then
    write(IMAIN,*) 'Mesh numbering:'
    write(IMAIN,*) '  Total number of elements: ',nspec_total
    write(IMAIN,*)
    write(IMAIN,*) '  Total number of acoustic elements           = ',nspec_acoustic_total
    write(IMAIN,*) '  Total number of elastic/visco/poro elements = ',nspec_total - nspec_acoustic_total
    write(IMAIN,*)
#ifdef WITH_MPI
    write(IMAIN,*) 'Approximate total number of grid points in the mesh'
    write(IMAIN,*) '(with a few duplicates coming from MPI buffers): ',nglob_total
#else
    write(IMAIN,*) 'Exact total number of grid points in the mesh: ',nglob_total
#endif

    ! percentage of elements with 2 degrees of freedom per point
    ratio_2DOFs = (nspec_total - nspec_acoustic_total) / dble(nspec_total)
    ratio_1DOF  = nspec_acoustic_total / dble(nspec_total)

    nb_acoustic_DOFs = nint(nglob_total*ratio_1DOF)

    ! elastic elements have two degrees of freedom per point
    nb_elastic_DOFs  = nint(nglob_total*ratio_2DOFs*2)

    if (P_SV) then
      write(IMAIN,*)
      write(IMAIN,*) 'Approximate number of acoustic degrees of freedom in the mesh: ',nb_acoustic_DOFs
      write(IMAIN,*) 'Approximate number of elastic degrees of freedom in the mesh: ',nb_elastic_DOFs
      write(IMAIN,*) '  (there are 2 degrees of freedom per point for elastic elements)'
      write(IMAIN,*)
      write(IMAIN,*) 'Approximate total number of degrees of freedom in the mesh'
      write(IMAIN,*) '(sum of the two values above): ',nb_acoustic_DOFs + nb_elastic_DOFs
      write(IMAIN,*)
      write(IMAIN,*) ' (for simplicity viscoelastic or poroelastic elements, if any,'
      write(IMAIN,*) '  are counted as elastic in the above three estimates;'
      write(IMAIN,*) '  in reality they have more degrees of freedom)'
      write(IMAIN,*)
    endif
    call flush_IMAIN()
  endif

  ! allocate temporary arrays
  allocate(integer_mask_ibool(nglob),stat=ier)
  if (ier /= 0 ) call stop_the_code('error allocating integer_mask_ibool')
  allocate(copy_ibool_ori(NGLLX,NGLLZ,nspec),stat=ier)
  if (ier /= 0 ) call stop_the_code('error allocating copy_ibool_ori')

  ! reduce cache misses by sorting the global numbering in the order in which it is accessed in the time loop.
  ! this speeds up the calculations significantly on modern processors
  call get_global()

  ! synchronizes all processes
  call synchronize_all()

  end subroutine setup_mesh_numbering

!
!-----------------------------------------------------------------------------------
!

  subroutine setup_mesh_coordinates()

  use constants, only: ZERO
  use specfem_par

  implicit none

  ! local parameters
  ! Jacobian matrix and determinant
  double precision :: xixl,xizl,gammaxl,gammazl,jacobianl
  double precision :: xi,gamma,x,z

  integer :: i,j,ispec,iglob,ier

  ! to help locate elements with a negative Jacobian using OpenDX
  logical :: found_a_negative_jacobian

  ! allocate other global arrays
  allocate(coord(NDIM,nglob),stat=ier)
  if (ier /= 0) call stop_the_code('Error allocating coord array')
  coord(:,:) = 0.d0

  ! sets the coordinates of the points of the global grid
  found_a_negative_jacobian = .false.
  do ispec = 1,nspec
    do j = 1,NGLLZ
      do i = 1,NGLLX
        if (AXISYM) then
          if (is_on_the_axis(ispec)) then
            xi = xiglj(i)
          else
            xi = xigll(i)
          endif
        else
          xi = xigll(i)
        endif
        gamma = zigll(j)

        call recompute_jacobian_with_negative_stop(xi,gamma,x,z,xixl,xizl,gammaxl,gammazl,jacobianl, &
                                                   coorg,knods,ispec,NGNOD,nspec,npgeo, &
                                                   .false.)

        if (jacobianl <= ZERO) found_a_negative_jacobian = .true.

        ! coordinates of global nodes
        iglob = ibool(i,j,ispec)
        coord(1,iglob) = x
        coord(2,iglob) = z

        xix(i,j,ispec) = real(xixl,kind=CUSTOM_REAL)
        xiz(i,j,ispec) = real(xizl,kind=CUSTOM_REAL)
        gammax(i,j,ispec) = real(gammaxl,kind=CUSTOM_REAL)
        gammaz(i,j,ispec) = real(gammazl,kind=CUSTOM_REAL)
        jacobian(i,j,ispec) = real(jacobianl,kind=CUSTOM_REAL)

      enddo
    enddo
  enddo

! create an OpenDX file containing all the negative elements displayed in red, if any
! this allows users to locate problems in a mesh based on the OpenDX file created at the second iteration
! do not create OpenDX files if no negative Jacobian has been found, or if we are running in parallel
! (because writing OpenDX routines is much easier in serial)
  if (found_a_negative_jacobian .and. NPROC == 1) then
    call save_openDX_jacobian(nspec,npgeo,NGNOD,knods,coorg,xigll,zigll,AXISYM,is_on_the_axis,xiglj)
  endif

  ! stop the code at the first negative element found, because such a mesh cannot be computed
  if (found_a_negative_jacobian) then
    do ispec = 1,nspec
      do j = 1,NGLLZ
        do i = 1,NGLLX
          if (AXISYM) then
            if (is_on_the_axis(ispec)) then
              xi = xiglj(i)
            else
              xi = xigll(i)
            endif
          else
            xi = xigll(i)
          endif
          gamma = zigll(j)

          call recompute_jacobian_with_negative_stop(xi,gamma,x,z,xixl,xizl,gammaxl,gammazl,jacobianl, &
                                                     coorg,knods,ispec,NGNOD,nspec,npgeo, &
                                                     .true.)
        enddo
      enddo
    enddo
  endif

  ! synchronizes all processes
  call synchronize_all()

  end subroutine setup_mesh_coordinates

!
!-----------------------------------------------------------------------------------
!

  subroutine setup_mesh_properties()

  use constants, only: IMAIN,OUTPUT_FILES
  use specfem_par
  use specfem_par_movie

  implicit none

  ! local parameters
  double precision :: xmin,xmax,zmin,zmax
  double precision :: xmin_local,xmax_local,zmin_local,zmax_local
  integer :: i,n

  ! determines mesh dimensions
  xmin_local = minval(coord(1,:))
  xmax_local = maxval(coord(1,:))
  zmin_local = minval(coord(2,:))
  zmax_local = maxval(coord(2,:))

  ! collect min/max
  call min_all_all_dp(xmin_local, xmin)
  call max_all_all_dp(xmax_local, xmax)
  call min_all_all_dp(zmin_local, zmin)
  call max_all_all_dp(zmax_local, zmax)

  ! user output
  if (myrank == 0) then
    write(IMAIN,*) 'Mesh dimensions:'
    write(IMAIN,*) '  Xmin,Xmax of the whole mesh = ',xmin,xmax
    write(IMAIN,*) '  Zmin,Zmax of the whole mesh = ',zmin,zmax
    write(IMAIN,*)
  endif

  ! saves the grid of points in a file
  if (output_grid_ASCII .and. myrank == 0) then
     write(IMAIN,*)
     write(IMAIN,*) 'Saving the grid in an ASCII text file...'
     write(IMAIN,*)
     open(unit=55,file=trim(OUTPUT_FILES)//'ASCII_dump_of_grid_points.txt',status='unknown')
     write(55,*) nglob
     do n = 1,nglob
        write(55,*) (coord(i,n), i = 1,NDIM)
     enddo
     close(55)
  endif

  ! plots the GLL mesh in a Gnuplot file
  if (output_grid_Gnuplot .and. myrank == 0) then
    call plot_gll()
  endif

  ! synchronizes all processes
  call synchronize_all()

  end subroutine setup_mesh_properties

!
!-----------------------------------------------------------------------------------
!

  subroutine setup_mesh_periodic_edges()

  use constants, only: IMAIN,NGLLX,NGLLZ,HUGEVAL
  use specfem_par

  implicit none

  ! local parameters
  integer :: ispec,i,j,iglob,iglob2,ier
  double precision :: xmaxval,xminval,ymaxval,yminval,xtol,xtypdist
  integer :: counter

! allocate an array to make sure that an acoustic free surface is not enforced on periodic edges
  allocate(this_ibool_is_a_periodic_edge(NGLOB),stat=ier)
  if (ier /= 0) call stop_the_code('Error allocating periodic edge array')

  this_ibool_is_a_periodic_edge(:) = .false.

! periodic conditions: detect common points between left and right edges and replace one of them with the other
  if (ADD_PERIODIC_CONDITIONS) then
    ! user output
    if (myrank == 0) then
      write(IMAIN,*)
      write(IMAIN,*) 'implementing periodic boundary conditions'
      write(IMAIN,*) 'in the horizontal direction with a periodicity distance of ',PERIODIC_HORIZ_DIST,' m'
      if (PERIODIC_HORIZ_DIST <= 0.d0) call stop_the_code( &
'PERIODIC_HORIZ_DIST should be greater than zero when using ADD_PERIODIC_CONDITIONS')
      write(IMAIN,*)
      write(IMAIN,*) '*****************************************************************'
      write(IMAIN,*) '*****************************************************************'
      write(IMAIN,*) '**** BEWARE: because of periodic conditions, values computed ****'
      write(IMAIN,*) '****         by check_grid() below will not be reliable       ****'
      write(IMAIN,*) '*****************************************************************'
      write(IMAIN,*) '*****************************************************************'
      write(IMAIN,*)
    endif

    ! set up a local geometric tolerance
    xtypdist = +HUGEVAL

    do ispec = 1,nspec

      xminval = +HUGEVAL
      yminval = +HUGEVAL
      xmaxval = -HUGEVAL
      ymaxval = -HUGEVAL

      ! only loop on the four corners of each element to get a typical size
      do j = 1,NGLLZ,NGLLZ-1
        do i = 1,NGLLX,NGLLX-1
          iglob = ibool(i,j,ispec)
          xmaxval = max(coord(1,iglob),xmaxval)
          xminval = min(coord(1,iglob),xminval)
          ymaxval = max(coord(2,iglob),ymaxval)
          yminval = min(coord(2,iglob),yminval)
        enddo
      enddo

      ! compute the minimum typical "size" of an element in the mesh
      xtypdist = min(xtypdist,xmaxval-xminval)
      xtypdist = min(xtypdist,ymaxval-yminval)

    enddo

    ! define a tolerance, small with respect to the minimum size
    xtol = 1.d-4 * xtypdist

! detect the points that are on the same horizontal line (i.e. at the same height Z)
! and that have a value of the horizontal coordinate X that differs by exactly the periodicity length;
! if so, make them all have the same global number, which will then implement periodic boundary conditions automatically.
! We select the smallest value of iglob and assign it to all the points that are the same due to periodicity,
! this way the maximum value of the ibool() array will remain as small as possible.
!
! *** IMPORTANT: this simple algorithm will be slow for large meshes because it has a cost of NGLOB^2 / 2
! (where NGLOB is the number of points per MPI slice, not of the whole mesh though). This could be
! reduced to O(NGLOB log(NGLOB)) by using a quicksort algorithm on the coordinates of the points to detect the multiples
! (as implemented in routine createnum_fast() elsewhere in the code). This could be done one day if needed instead
! of the very simple double loop below.
    if (myrank == 0) then
      write(IMAIN,*) 'start detecting points for periodic boundary conditions '// &
                     '(the current algorithm can be slow and could be improved)...'
    endif

    counter = 0
    do iglob = 1,NGLOB-1
      do iglob2 = iglob + 1,NGLOB
        ! check if the two points have the exact same Z coordinate
        if (abs(coord(2,iglob2) - coord(2,iglob)) < xtol) then
          ! if so, check if their X coordinate differs by exactly the periodicity distance
          if (abs(abs(coord(1,iglob2) - coord(1,iglob)) - PERIODIC_HORIZ_DIST) < xtol) then
            ! if so, they are the same point, thus replace the highest value of ibool with the lowest
            ! to make them the same global point and thus implement periodicity automatically
            counter = counter + 1
            this_ibool_is_a_periodic_edge(iglob) = .true.
            this_ibool_is_a_periodic_edge(iglob2) = .true.
            do ispec = 1,nspec
              do j = 1,NGLLZ
                do i = 1,NGLLX
                  if (ibool(i,j,ispec) == iglob2) ibool(i,j,ispec) = iglob
                enddo
              enddo
            enddo
          endif
        endif
      enddo
    enddo

    if (myrank == 0) write(IMAIN,*) 'done detecting points for periodic boundary conditions.'

    if (counter > 0) write(IMAIN,*) 'implemented periodic conditions on ',counter,' grid points on proc ',myrank

  endif ! of if (ADD_PERIODIC_CONDITIONS)

  end subroutine setup_mesh_periodic_edges

!
!-----------------------------------------------------------------------------------
!

  subroutine setup_mesh_acoustic_forcing_edges()

! acoustic forcing edge detection

  use constants, only: IMAIN,IBOTTOM,IRIGHT,ITOP,ILEFT
  use specfem_par

  implicit none

  ! local parameters
  integer :: ipoin1D

  ! acoustic forcing edge detection
  ! the elements forming an edge are already known (computed in meshfem2D),
  ! the common nodes forming the edge are computed here
  if (ACOUSTIC_FORCING) then

    ! user output
    if (myrank == 0) then
      write(IMAIN,*)
      write(IMAIN,*) 'Acoustic forcing simulation'
      write(IMAIN,*)
      write(IMAIN,*) 'Beginning of acoustic forcing edge detection'
      call flush_IMAIN()
    endif

    ! define i and j points for each edge
    do ipoin1D = 1,NGLLX

      ivalue(ipoin1D,IBOTTOM) = NGLLX - ipoin1D + 1
      ivalue_inverse(ipoin1D,IBOTTOM) = ipoin1D
      jvalue(ipoin1D,IBOTTOM) = NGLLZ
      jvalue_inverse(ipoin1D,IBOTTOM) = NGLLZ

      ivalue(ipoin1D,IRIGHT) = 1
      ivalue_inverse(ipoin1D,IRIGHT) = 1
      jvalue(ipoin1D,IRIGHT) = NGLLZ - ipoin1D + 1
      jvalue_inverse(ipoin1D,IRIGHT) = ipoin1D

      ivalue(ipoin1D,ITOP) = ipoin1D
      ivalue_inverse(ipoin1D,ITOP) = NGLLX - ipoin1D + 1
      jvalue(ipoin1D,ITOP) = 1
      jvalue_inverse(ipoin1D,ITOP) = 1

      ivalue(ipoin1D,ILEFT) = NGLLX
      ivalue_inverse(ipoin1D,ILEFT) = NGLLX
      jvalue(ipoin1D,ILEFT) = ipoin1D
      jvalue_inverse(ipoin1D,ILEFT) = NGLLZ - ipoin1D + 1

    enddo

  endif ! if (ACOUSTIC_FORCING)

  ! synchronizes all processes
  call synchronize_all()

  end subroutine setup_mesh_acoustic_forcing_edges

!
!-----------------------------------------------------------------------------------
!

  subroutine setup_mesh_material_properties()

! external models

  use constants, only: IMAIN,FOUR_THIRDS,TWO_THIRDS
  use specfem_par

  implicit none

  ! local parameters
  integer :: nspec_ext,nspec_tmp,nspec_all
  integer :: i,j,ispec,ier,imaterial
  ! temporary arrays for reading
  real(kind=CUSTOM_REAL), dimension(:,:,:), allocatable :: rhoext,vsext,vpext
  real(kind=CUSTOM_REAL), dimension(:,:,:), allocatable :: QKappa_attenuationext,Qmu_attenuationext
  real(kind=CUSTOM_REAL), dimension(:,:,:), allocatable :: c11ext,c12ext,c13ext,c15ext,c22ext,c23ext,c25ext, &
                                                           c33ext,c35ext,c55ext

  ! for shifting of velocities if needed in the case of viscoelasticity
  double precision :: vp,vs,rhol,mul,lambdal,kappal,qmul,qkappal
  double precision :: phi,tort,kappa_s,kappa_f,kappa_fr,mu_s,mu_fr
  double precision :: rho_s,rho_f,rho_bar,eta_f,w_c
  double precision :: D_biot,H_biot,C_biot,M_biot
  double precision :: cpIsquare,cpIIsquare,cssquare,vpII
  double precision :: perm_xx,perm_xz,perm_zz

  ! collects total number
  call sum_all_i(nspec,nspec_all)

  ! The following line is important. For external model defined from tomography file ; material line in Par_file like that:
  ! model_number -1 0 0 A 0 0 0 0 0 0 0 0 0 0
  ! because in that case MODEL = "default" but nspec_ext = nspec
  if (tomo_material > 0) MODEL = 'tomo'

  ! user output
  if (myrank == 0) then
    write(IMAIN,*) 'Material properties:'
    write(IMAIN,*) '  MODEL                 : ',trim(MODEL)
    write(IMAIN,*) '  nspec                 : ',nspec_all
    write(IMAIN,*) '  assign external model : ',assign_external_model
    write(IMAIN,*)
    call flush_IMAIN()
  endif

  ! allocates material arrays
  if (assign_external_model) then
    nspec_ext = nspec
  else
    ! dummy allocations
    nspec_ext = 1
  endif

  ! allocates temporary material arrays for reading external model values (vp vs rho QKappa Qmu)
  allocate(vpext(NGLLX,NGLLZ,nspec_ext), &
           vsext(NGLLX,NGLLZ,nspec_ext), &
           rhoext(NGLLX,NGLLZ,nspec_ext), &
           QKappa_attenuationext(NGLLX,NGLLZ,nspec_ext), &
           Qmu_attenuationext(NGLLX,NGLLZ,nspec_ext),stat=ier)
  if (ier /= 0) call stop_the_code('Error allocating external model arrays for vp vs rho attenuation')
  vpext(:,:,:) = 0.0_CUSTOM_REAL; vsext(:,:,:) = 0.0_CUSTOM_REAL; rhoext(:,:,:) = 0.0_CUSTOM_REAL
  QKappa_attenuationext(:,:,:) = 0.0_CUSTOM_REAL
  Qmu_attenuationext(:,:,:) = 0.0_CUSTOM_REAL

  ! allocates temporary material arrays for c11 c13 c15 c33 c35 c55 c12 c23 c25 c22
  allocate(c11ext(NGLLX,NGLLZ,nspec_ext), &
           c13ext(NGLLX,NGLLZ,nspec_ext), &
           c15ext(NGLLX,NGLLZ,nspec_ext), &
           c33ext(NGLLX,NGLLZ,nspec_ext), &
           c35ext(NGLLX,NGLLZ,nspec_ext), &
           c55ext(NGLLX,NGLLZ,nspec_ext), &
           c12ext(NGLLX,NGLLZ,nspec_ext), &
           c23ext(NGLLX,NGLLZ,nspec_ext), &
           c25ext(NGLLX,NGLLZ,nspec_ext), &
           c22ext(NGLLX,NGLLZ,nspec_ext),stat=ier)
  if (ier /= 0) call stop_the_code('Error allocating external model arrays for anisotropy')
  c11ext(:,:,:) = 0.0_CUSTOM_REAL; c13ext(:,:,:) = 0.0_CUSTOM_REAL; c15ext(:,:,:) = 0.0_CUSTOM_REAL
  c33ext(:,:,:) = 0.0_CUSTOM_REAL; c35ext(:,:,:) = 0.0_CUSTOM_REAL; c55ext(:,:,:) = 0.0_CUSTOM_REAL
  c12ext(:,:,:) = 0.0_CUSTOM_REAL; c23ext(:,:,:) = 0.0_CUSTOM_REAL; c25ext(:,:,:) = 0.0_CUSTOM_REAL
  c22ext(:,:,:) = 0.0_CUSTOM_REAL

  ! reads in external models
  if (assign_external_model) then
    ! user output
    if (myrank == 0) then
      write(IMAIN,*) '  assigning an external velocity and density model'
      call flush_IMAIN()
    endif

    call read_external_model(rhoext,vpext,vsext,QKappa_attenuationext,Qmu_attenuationext, &
                             nspec_ext,c11ext,c12ext,c13ext,c15ext,c22ext,c23ext,c25ext,c33ext,c35ext,c55ext)
  endif

  ! allocates material arrays (acoustic/elastic/poroelastic - isotropic)
  allocate(kappastore(NGLLX,NGLLZ,nspec), &
           mustore(NGLLX,NGLLZ,nspec), &
           rhostore(NGLLX,NGLLZ,nspec), &
           qkappa_attenuation_store(NGLLX,NGLLZ,nspec), &
           qmu_attenuation_store(NGLLX,NGLLZ,nspec), &
           rho_vpstore(NGLLX,NGLLZ,nspec), &
           rho_vsstore(NGLLX,NGLLZ,nspec),stat=ier)
  if (ier /= 0) call stop_the_code('Error allocating material arrays')

  kappastore(:,:,:) = 0.0_CUSTOM_REAL
  mustore(:,:,:) = 0.0_CUSTOM_REAL
  rhostore(:,:,:) = 0.0_CUSTOM_REAL
  qkappa_attenuation_store(:,:,:) = 0.0_CUSTOM_REAL
  qmu_attenuation_store(:,:,:) = 0.0_CUSTOM_REAL
  rho_vpstore(:,:,:) = 0.0_CUSTOM_REAL
  rho_vsstore(:,:,:) = 0.0_CUSTOM_REAL

  ! poroelastic materials
  if (any_poroelastic) then
    nspec_tmp = nspec
  else
    nspec_tmp = 1  ! for dummy allocation
  endif

  ! allocates arrays (needed if poroelastic domains present in this slice)
  allocate(tortstore(NGLLX,NGLLZ,nspec_tmp), &
           phistore(NGLLX,NGLLZ,nspec_tmp), &
           rhoarraystore(2,NGLLX,NGLLZ,nspec_tmp), &
           kappaarraystore(3,NGLLX,NGLLZ,nspec_tmp), &
           permstore(3,NGLLX,NGLLZ,nspec_tmp), &
           etastore(NGLLX,NGLLZ,nspec_tmp), &
           vpIIstore(NGLLX,NGLLZ,nspec_tmp), &
           mufr_store(NGLLX,NGLLZ,nspec_tmp),stat=ier)
  if (ier /= 0) call stop_the_code('Error allocating poroelastic material arrays')
  tortstore(:,:,:) = 0.0_CUSTOM_REAL
  phistore(:,:,:) = 0.0_CUSTOM_REAL
  rhoarraystore(:,:,:,:) = 0.0_CUSTOM_REAL
  kappaarraystore(:,:,:,:) = 0.0_CUSTOM_REAL
  permstore(:,:,:,:) = 0.0_CUSTOM_REAL
  etastore(:,:,:) = 0.0_CUSTOM_REAL
  vpIIstore(:,:,:) = 0.0_CUSTOM_REAL
  mufr_store(:,:,:) = 0.0_CUSTOM_REAL

  ! user output
  if (myrank == 0) then
    write(IMAIN,*) '  setting up material arrays'
    call flush_IMAIN()
  endif

  ! sets new material properties
  ! note: velocities might have been shifted by attenuation
  do ispec = 1,nspec
    do j = 1,NGLLZ
      do i = 1,NGLLX
        ! gets material values
        if (assign_external_model) then
          ! external model
          rhol = rhoext(i,j,ispec)
          vp = vpext(i,j,ispec)
          vs = vsext(i,j,ispec)
          ! determins mu and kappa
          mul = rhol * vs * vs
          if (AXISYM) then ! CHECK kappa
            kappal = rhol * vp * vp - FOUR_THIRDS * mul   ! kappa derived from vp,vs
          else
            kappal = rhol * vp * vp - mul
          endif
          ! to compare:
          !lambdal = rhol * vp*vp - TWO * mul
          !if (AXISYM) then ! CHECK kappa
          !  kappal = lambdal + TWO_THIRDS * mul
          !  vp = sqrt((kappal + FOUR_THIRDS * mul)/rhol)
          !else
          !  kappal = lambdal + mul
          !  vp = sqrt((kappal + mul)/rhol)
          !endif
          !
          ! and/or:
          !if (AXISYM) then
          !  lambdal = kappal - TWO_THIRDS * mul
          !else
          !  lambdal = kappal - mul
          !endif
          !attenuation
          qmul = Qmu_attenuationext(i,j,ispec)
          qkappal = QKappa_attenuationext(i,j,ispec)
        else
          ! internal mesh
          imaterial = kmato(ispec)

          rhol = density(1,imaterial)
          lambdal = poroelastcoef(1,1,imaterial)
          mul = poroelastcoef(2,1,imaterial)

          if (AXISYM) then ! CHECK kappa
            kappal = lambdal + TWO_THIRDS * mul           ! kappa derived from lame parameters lambda,mu
            vp = sqrt((kappal + FOUR_THIRDS * mul)/rhol)
          else
            kappal = lambdal + mul
            vp = sqrt((kappal + mul)/rhol)
          endif
          ! attenuation
          qmul = Qmu_attenuationcoef(imaterial)
          qkappal = Qkappa_attenuationcoef(imaterial)
        endif

        ! note: poroelastic materials are only defined using internal meshes so far, no external model defines it yet.
        !       in future, this might change and the corresponding arrays might have to be taken below.

        ! overimposes values for poroelastic elements
        if (ispec_is_poroelastic(ispec)) then
          ! poroelastic material
          call get_poroelastic_material(ispec,phi,tort,mu_s,kappa_s,rho_s,kappa_f,rho_f,eta_f,mu_fr,kappa_fr,rho_bar)

          ! Biot coefficients for the input phi
          call get_poroelastic_Biot_coeff(phi,kappa_s,kappa_f,kappa_fr,mu_fr,D_biot,H_biot,C_biot,M_biot)

          ! permeability
          perm_xx = permeability(1,kmato(ispec))
          perm_xz = permeability(2,kmato(ispec))
          perm_zz = permeability(3,kmato(ispec))

          ! computes velocities
          call get_poroelastic_velocities(cpIsquare,cpIIsquare,cssquare,H_biot,C_biot,M_biot,mu_fr,phi, &
                                          tort,rho_s,rho_f,eta_f,perm_xx, &
                                          f0_source(1),freq0_poroelastic,Q0_poroelastic,w_c,ATTENUATION_PORO_FLUID_PART)

          vp = sqrt(cpIsquare)    ! vpI
          vpII = sqrt(cpIIsquare) ! vpII
          vs = sqrt(cssquare)

          rhol = rho_s            ! for density array rhostore used in check_grid()
          mul = rhol * vs * vs    ! for shear modulus used in check_grid()

          ! stores specific poroelastic properties
          phistore(i,j,ispec) = phi
          tortstore(i,j,ispec) = tort

          rhoarraystore(1,i,j,ispec) = rho_s    ! density for solid part
          rhoarraystore(2,i,j,ispec) = rho_f    ! density for fluid part

          kappaarraystore(1,i,j,ispec) = kappa_s  ! solid
          kappaarraystore(2,i,j,ispec) = kappa_f  ! fluid
          kappaarraystore(3,i,j,ispec) = kappa_fr ! frame

          mufr_store(i,j,ispec) = mu_fr   ! frame
          etastore(i,j,ispec) = eta_f     ! fluid

          permstore(1,i,j,ispec) = perm_xx
          permstore(2,i,j,ispec) = perm_xz
          permstore(3,i,j,ispec) = perm_zz

          vpIIstore(i,j,ispec) = vpII           ! for stacey and check_grid() routines
        endif

        ! stores moduli
        rhostore(i,j,ispec) = rhol
        mustore(i,j,ispec) = mul
        kappastore(i,j,ispec) = kappal

        qmu_attenuation_store(i,j,ispec) = qmul
        qkappa_attenuation_store(i,j,ispec) = qkappal

        ! stores density times vp and vs
        vs = sqrt(mul/rhol)

        rho_vpstore(i,j,ispec) = rhol * vp
        rho_vsstore(i,j,ispec) = rhol * vs
      enddo
    enddo
  enddo

  ! anisotropy
  if (any_anisotropy .or. nspec_ext == nspec) then
    nspec_tmp = nspec
  else
    nspec_tmp = 1  ! for dummy allocation
  endif

  ! allocates arrays in case of anisotropy (needed if anisotropic elements present in this slice)
  allocate(c11store(NGLLX,NGLLZ,nspec_tmp), &
           c12store(NGLLX,NGLLZ,nspec_tmp), &
           c13store(NGLLX,NGLLZ,nspec_tmp), &
           c15store(NGLLX,NGLLZ,nspec_tmp), &
           c22store(NGLLX,NGLLZ,nspec_tmp), &
           c23store(NGLLX,NGLLZ,nspec_tmp), &
           c25store(NGLLX,NGLLZ,nspec_tmp), &
           c33store(NGLLX,NGLLZ,nspec_tmp), &
           c35store(NGLLX,NGLLZ,nspec_tmp), &
           c55store(NGLLX,NGLLZ,nspec_tmp),stat=ier)
  if (ier /= 0) call stop_the_code('Error allocating aniso material arrays')
  c11store(:,:,:) = 0.0_CUSTOM_REAL
  c12store(:,:,:) = 0.0_CUSTOM_REAL
  c13store(:,:,:) = 0.0_CUSTOM_REAL
  c15store(:,:,:) = 0.0_CUSTOM_REAL
  c22store(:,:,:) = 0.0_CUSTOM_REAL
  c23store(:,:,:) = 0.0_CUSTOM_REAL
  c25store(:,:,:) = 0.0_CUSTOM_REAL
  c33store(:,:,:) = 0.0_CUSTOM_REAL
  c35store(:,:,:) = 0.0_CUSTOM_REAL
  c55store(:,:,:) = 0.0_CUSTOM_REAL

  ! sets anisotropic parameters
  if (any_anisotropy .or. nspec_tmp == nspec) then
    ! user output
    if (myrank == 0) then
      write(IMAIN,*) '  setting up anisotropic arrays'
      call flush_IMAIN()
    endif

    do ispec = 1,nspec
      ! checks anisotropic flag only valid for elastic elements
      if (.not. ispec_is_elastic(ispec)) then
        if (ispec_is_anisotropic(ispec)) then
          print *,'Error: element ',ispec,' has anisotropy but is not elastic! this is not supported yet!'
          print *,'  element ',ispec,' has flags acoustic: ',ispec_is_acoustic(ispec), &
                  'elastic: ',ispec_is_elastic(ispec),' poroelastic: ',ispec_is_poroelastic(ispec)
          stop 'Invalid anisotropy flag for non-elastic element'
        endif
      endif

      ! fills anisotropic store
      ! there's no need to distinguish between elastic and non-elastic elements
      ! for non-elastic elements, the values in arrays c11ext,.. or anistropycoef(..) are just zero
      do j = 1,NGLLZ
        do i = 1,NGLLX
          if (assign_external_model) then
            c11store(i,j,ispec) = c11ext(i,j,ispec)
            c12store(i,j,ispec) = c12ext(i,j,ispec)
            c13store(i,j,ispec) = c13ext(i,j,ispec)
            c15store(i,j,ispec) = c15ext(i,j,ispec)
            c22store(i,j,ispec) = c22ext(i,j,ispec) ! for AXISYM
            c23store(i,j,ispec) = c23ext(i,j,ispec)
            c25store(i,j,ispec) = c25ext(i,j,ispec)
            c33store(i,j,ispec) = c33ext(i,j,ispec)
            c35store(i,j,ispec) = c35ext(i,j,ispec)
            c55store(i,j,ispec) = c55ext(i,j,ispec)
          else
            c11store(i,j,ispec) = real(anisotropycoef(1,kmato(ispec)),kind=CUSTOM_REAL)  ! c11
            c13store(i,j,ispec) = real(anisotropycoef(2,kmato(ispec)),kind=CUSTOM_REAL)  ! c13
            c15store(i,j,ispec) = real(anisotropycoef(3,kmato(ispec)),kind=CUSTOM_REAL)  ! c15
            c33store(i,j,ispec) = real(anisotropycoef(4,kmato(ispec)),kind=CUSTOM_REAL)  ! c33
            c35store(i,j,ispec) = real(anisotropycoef(5,kmato(ispec)),kind=CUSTOM_REAL)  ! c35
            c55store(i,j,ispec) = real(anisotropycoef(6,kmato(ispec)),kind=CUSTOM_REAL)  ! c55
            c12store(i,j,ispec) = real(anisotropycoef(7,kmato(ispec)),kind=CUSTOM_REAL)  ! c12
            c23store(i,j,ispec) = real(anisotropycoef(8,kmato(ispec)),kind=CUSTOM_REAL)  ! c23
            c25store(i,j,ispec) = real(anisotropycoef(9,kmato(ispec)),kind=CUSTOM_REAL)  ! c25
            c22store(i,j,ispec) = real(anisotropycoef(10,kmato(ispec)),kind=CUSTOM_REAL) ! c22 for AXISYM
          endif
        enddo
      enddo
    enddo
  endif

  ! free temporary arrays
  deallocate(rhoext,vpext,vsext)
  deallocate(QKappa_attenuationext,Qmu_attenuationext)
  deallocate(c11ext,c13ext,c15ext,c33ext,c35ext,c55ext,c12ext,c23ext,c25ext,c22ext)

  ! user output
  if (myrank == 0) then
    write(IMAIN,*) '  all material arrays done'
    write(IMAIN,*)
    call flush_IMAIN()
  endif

  ! synchronizes all processes
  call synchronize_all()

  end subroutine setup_mesh_material_properties

!
!-----------------------------------------------------------------------------------
!

  subroutine setup_mesh_basic_check()

! basic checks on mesh parameters

  use specfem_par

  implicit none

  ! local parameters
  integer :: ispec

  ! performs basic checks on parameters read
  ! mutually exclusive domain flags (element can only belong to a single domain)
  do ispec = 1,nspec
    ! exclusive domain flags
    if (ispec_is_acoustic(ispec) .and. ispec_is_elastic(ispec)) &
      call stop_the_code('Error invalid domain element found! element is acoustic and elastic, please check...')

    if (ispec_is_acoustic(ispec) .and. ispec_is_poroelastic(ispec)) &
      call stop_the_code('Error invalid domain element found! element is acoustic and poroelastic, please check...')

    if (ispec_is_elastic(ispec) .and. ispec_is_poroelastic(ispec)) &
      call stop_the_code('Error invalid domain element found! element is elastic and poroelastic, please check...')

    ! un-assigned element
    if ((.not. ispec_is_acoustic(ispec)) .and. &
        (.not. ispec_is_elastic(ispec)) .and. &
        (.not. ispec_is_poroelastic(ispec))) &
      call stop_the_code('Error invalid domain element found! element has no domain (acoustic, elastic, or poroelastic), &
            & please check...')
  enddo

  ! synchronizes all processes
  call synchronize_all()

  end subroutine setup_mesh_basic_check

!
!-----------------------------------------------------------------------------------
!

  subroutine setup_mesh_domains()

! assigns global domain flags
!
! note: we call this routine only after we have read in a (possible) external model

  use constants, only: IMAIN
  use specfem_par

  implicit none

  ! local parameters
  integer :: nspec_acoustic_all,nspec_elastic_all,nspec_poroelastic_all,nspec_anisotropic_all
  integer :: nspec_total,nspec_in_domains

  ! re-counts domain elements
  call get_simulation_domain_counts()

  ! gets total numbers for all slices (collected on main only)
  call sum_all_i(nspec_acoustic,nspec_acoustic_all)
  call sum_all_i(nspec_elastic,nspec_elastic_all)
  call sum_all_i(nspec_poroelastic,nspec_poroelastic_all)
  call sum_all_i(nspec_aniso,nspec_anisotropic_all)

  ! user output
  if (myrank == 0) then
    write(IMAIN,*) 'Domains:'
    write(IMAIN,*) '  total number of acoustic elements        = ',nspec_acoustic_all
    write(IMAIN,*) '  total number of elastic elements         = ',nspec_elastic_all
    if (nspec_anisotropic_all > 0) then
      write(IMAIN,*) '    with number of anisotropic elements         = ',nspec_anisotropic_all
    endif
    write(IMAIN,*) '  total number of poroelastic elements     = ',nspec_poroelastic_all
  endif

  nspec_in_domains = nspec_acoustic_all + nspec_elastic_all + nspec_poroelastic_all

  ! checks with total
  call sum_all_i(nspec,nspec_total)
  if (myrank == 0) then
    if (nspec_total /= nspec_in_domains) then
      write(IMAIN,*) 'Error invalid total number of elements from domains ',nspec_in_domains,'instead of',nspec_total
      call exit_MPI(myrank,'Invalid total number of domain elements')
    endif
  endif

  ! purely anisotropic
  all_anisotropic = .false.
  if (count(ispec_is_anisotropic(:) .eqv. .true.) == nspec) all_anisotropic = .true.

  ! global domain flags
  ! (sets global flag for all slices)
  call any_all_l(any_elastic, ELASTIC_SIMULATION)
  call any_all_l(any_acoustic, ACOUSTIC_SIMULATION)
  call any_all_l(any_poroelastic, POROELASTIC_SIMULATION)

  ! check for solid attenuation
  if (.not. ELASTIC_SIMULATION .and. .not. ACOUSTIC_SIMULATION) then
    if (ATTENUATION_VISCOELASTIC) call exit_MPI(myrank,'currently cannot have attenuation if poroelastic simulation only')
  endif

  ! safety check
  if (POROELASTIC_SIMULATION) then
    if (ATTENUATION_PORO_FLUID_PART .and. time_stepping_scheme /= 1) &
      call stop_the_code('RK and LDDRK time scheme not supported for poroelastic simulations with attenuation')
  endif

! absorbing boundaries work, but not perfect for anisotropic
!  if (all_anisotropic .and. anyabs) &
!    call exit_MPI(myrank,'Cannot put absorbing boundaries if anisotropic materials along edges')

  if (ATTENUATION_VISCOELASTIC .and. all_anisotropic) then
    call exit_MPI(myrank,'Cannot turn attenuation on in anisotropic materials for now (not implemented yet, but could be done)')
  endif

  ! synchronizes all processes
  call synchronize_all()

  end subroutine setup_mesh_domains

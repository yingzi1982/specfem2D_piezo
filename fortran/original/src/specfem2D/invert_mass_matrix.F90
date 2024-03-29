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

  subroutine invert_mass_matrix_init()

!  builds the global mass matrix

  use constants, only: IMAIN,CUSTOM_REAL,NGLLX,NGLLZ,ONE,TWO,TWO_THIRDS,FOUR_THIRDS, &
                       CPML_X_ONLY,CPML_Z_ONLY,CPML_XZ, &
                       IEDGE1,IEDGE2,IEDGE3,IEDGE4

  use specfem_par, only: myrank,any_elastic,any_acoustic,any_poroelastic, &
                         rmass_inverse_elastic, &
                         rmass_inverse_acoustic,rmass_inverse_e1,ATTENUATION_VISCOACOUSTIC,phi_nu1,N_SLS, &
                         time_stepping_scheme,rmass_s_inverse_poroelastic,rmass_w_inverse_poroelastic, &
                         nspec,ibool,wxgll,wzgll,jacobian, &
                         ispec_is_elastic,ispec_is_acoustic,ispec_is_poroelastic, &
                         phistore,tortstore,rhoarraystore, &
                         rhostore,kappastore, &
                         deltatover2, &
                         gammaz, &
                         AXISYM,is_on_the_axis,coord,wxglj,xiglj, &
                         time_stepping_scheme,STACEY_ABSORBING_CONDITIONS

  ! PML arrays
  use specfem_par, only: PML_BOUNDARY_CONDITIONS,ispec_is_PML,region_CPML,spec_to_PML, &
                         K_x_store,K_z_store,d_x_store,d_z_store

  implicit none

  ! local parameter
  integer :: ispec,i,j,iglob

  ! material properties of the elastic medium
  real(kind=CUSTOM_REAL) :: xxi
  real(kind=CUSTOM_REAL) :: phinu1

  double precision :: rhol,kappal_relaxed
  double precision :: rho_s,rho_f,rho_bar,phi,tort

  integer :: ispec_PML
  logical :: this_element_has_PML

  integer :: i_sls

  if (myrank == 0) then
    write(IMAIN,*) "  initializing mass matrices"
    call flush_IMAIN()
  endif

  ! initialize mass matrix
  if (any_elastic) then
    rmass_inverse_elastic(:,:) = 0._CUSTOM_REAL
  endif

  if (any_poroelastic) then
    rmass_s_inverse_poroelastic(:) = 0._CUSTOM_REAL
    rmass_w_inverse_poroelastic(:) = 0._CUSTOM_REAL
  endif

  if (any_acoustic) then
    rmass_inverse_acoustic(:) = 0._CUSTOM_REAL
    if (ATTENUATION_VISCOACOUSTIC) rmass_inverse_e1(:,:) = 0._CUSTOM_REAL
  endif

  ! computes mass matrix for each element (poroelastic/elastic/acoustic)
  do ispec = 1,nspec
    do j = 1,NGLLZ
      do i = 1,NGLLX
        iglob = ibool(i,j,ispec)

        ! gets density model (elastic or acoustic)
        rhol = rhostore(i,j,ispec)
        kappal_relaxed = kappastore(i,j,ispec)

        if (ispec_is_poroelastic(ispec)) then
          ! material is poroelastic

          !!! PML NOT WORKING YET !!!
          this_element_has_PML = .false.
          if (PML_BOUNDARY_CONDITIONS) then
            if (ispec_is_PML(ispec)) call stop_the_code('PML not implemented yet for poroelastic case')
          endif

          phi = phistore(i,j,ispec)
          tort = tortstore(i,j,ispec)

          rho_s = rhoarraystore(1,i,j,ispec)
          rho_f = rhoarraystore(2,i,j,ispec)

          rho_bar = (1.d0-phi)*rho_s + phi*rho_f

          ! for the solid mass matrix
          rmass_s_inverse_poroelastic(iglob) = rmass_s_inverse_poroelastic(iglob) &
                  + wxgll(i)*wzgll(j)*jacobian(i,j,ispec)*(rho_bar - phi*rho_f/tort)
          ! for the fluid mass matrix
          rmass_w_inverse_poroelastic(iglob) = rmass_w_inverse_poroelastic(iglob) &
                  + wxgll(i)*wzgll(j)*jacobian(i,j,ispec)*(rho_bar*rho_f*tort - phi*rho_f*rho_f)/(rho_bar*phi)

        else if (ispec_is_elastic(ispec)) then
          ! for elastic medium

          this_element_has_PML = .false.
          if (PML_BOUNDARY_CONDITIONS .and. ispec_is_PML(ispec)) this_element_has_PML = .true.

          if (this_element_has_PML) then
            ! PML
            ispec_PML = spec_to_PML(ispec)

            ! mass matrix contribution for PML
            if (region_CPML(ispec) == CPML_X_ONLY) then
              if (AXISYM) then  ! This PML can't be on the axis
                rmass_inverse_elastic(1,iglob) = rmass_inverse_elastic(1,iglob) &
                     + coord(1,iglob)*wxgll(i)*wzgll(j)*rhol*jacobian(i,j,ispec) * (K_x_store(i,j,ispec_PML))
              else ! not axisym
                rmass_inverse_elastic(1,iglob) = rmass_inverse_elastic(1,iglob) &
                     + wxgll(i)*wzgll(j)*rhol*jacobian(i,j,ispec) * (K_x_store(i,j,ispec_PML))
              endif
              rmass_inverse_elastic(2,iglob) = rmass_inverse_elastic(1,iglob)

            else if (region_CPML(ispec) == CPML_XZ) then
              if (AXISYM) then  ! This corner can't be on the axis
                rmass_inverse_elastic(1,iglob) = rmass_inverse_elastic(1,iglob) &
                     + coord(1,iglob)*wxgll(i)*wzgll(j)*rhol*jacobian(i,j,ispec) &
                     * (K_x_store(i,j,ispec_PML) * K_z_store(i,j,ispec_PML))
              else ! not axisym
                rmass_inverse_elastic(1,iglob) = rmass_inverse_elastic(1,iglob) &
                     + wxgll(i)*wzgll(j)*rhol*jacobian(i,j,ispec) * (K_x_store(i,j,ispec_PML) * K_z_store(i,j,ispec_PML))
              endif
              rmass_inverse_elastic(2,iglob) = rmass_inverse_elastic(1,iglob)

            else if (region_CPML(ispec) == CPML_Z_ONLY) then
              if (AXISYM) then
                if (is_on_the_axis(ispec)) then
                  if (is_on_the_axis(ispec) .and. i == 1) then ! First GLJ point
                    xxi = + gammaz(i,j,ispec) * jacobian(i,j,ispec)
                    rmass_inverse_elastic(1,iglob) = rmass_inverse_elastic(1,iglob) &
                       + xxi*wxglj(i)*wzgll(j)*rhol*jacobian(i,j,ispec) * (K_z_store(i,j,ispec_PML))
                  else
                    rmass_inverse_elastic(1,iglob) = rmass_inverse_elastic(1,iglob) &
                       + coord(1,iglob)/(xiglj(i)+ONE)*wxglj(i)*wzgll(j)*rhol*jacobian(i,j,ispec) * (K_z_store(i,j,ispec_PML))
                  endif
                else ! not on the axis
                  rmass_inverse_elastic(1,iglob) = rmass_inverse_elastic(1,iglob) &
                     + coord(1,iglob)*wxgll(i)*wzgll(j)*rhol*jacobian(i,j,ispec) * (K_z_store(i,j,ispec_PML))
                endif
              else ! not axisym
                rmass_inverse_elastic(1,iglob) = rmass_inverse_elastic(1,iglob) &
                     + wxgll(i)*wzgll(j)*rhol*jacobian(i,j,ispec) * (K_z_store(i,j,ispec_PML))
              endif
              rmass_inverse_elastic(2,iglob) = rmass_inverse_elastic(1,iglob)
            endif

            ! adds additional Newmark term (dt/2 * C) to mass matrix for stabilization
            if (time_stepping_scheme == 1) then
              ! Newmark
              if (region_CPML(ispec) == CPML_X_ONLY) then
                if (AXISYM) then  ! This PML can't be on the axis
                   rmass_inverse_elastic(1,iglob) = rmass_inverse_elastic(1,iglob) &
                        + coord(1,iglob)*wxgll(i)*wzgll(j)*rhol*jacobian(i,j,ispec) * (d_x_store(i,j,ispec_PML) * deltatover2)
                else ! not axisym
                   rmass_inverse_elastic(1,iglob) = rmass_inverse_elastic(1,iglob) &
                        + wxgll(i)*wzgll(j)*rhol*jacobian(i,j,ispec) * (d_x_store(i,j,ispec_PML) * deltatover2)
                endif
                rmass_inverse_elastic(2,iglob) = rmass_inverse_elastic(1,iglob)

              else if (region_CPML(ispec) == CPML_XZ) then
                if (AXISYM) then  ! This corner can't be on the axis
                   rmass_inverse_elastic(1,iglob) = rmass_inverse_elastic(1,iglob)  &
                        + coord(1,iglob)*wxgll(i)*wzgll(j)*rhol*jacobian(i,j,ispec) &
                        * ((d_x_store(i,j,ispec_PML)*k_z_store(i,j,ispec_PML) + &
                            d_z_store(i,j,ispec_PML)*k_x_store(i,j,ispec_PML)) * deltatover2)
                else ! not axisym
                   rmass_inverse_elastic(1,iglob) = rmass_inverse_elastic(1,iglob) &
                        + wxgll(i)*wzgll(j)*rhol*jacobian(i,j,ispec) &
                        * ((d_x_store(i,j,ispec_PML)*k_z_store(i,j,ispec_PML) + &
                            d_z_store(i,j,ispec_PML)*k_x_store(i,j,ispec_PML)) * deltatover2)
                endif
                rmass_inverse_elastic(2,iglob) = rmass_inverse_elastic(1,iglob)

              else if (region_CPML(ispec) == CPML_Z_ONLY) then
                if (AXISYM) then
                  if (is_on_the_axis(ispec)) then
                    if (is_on_the_axis(ispec) .and. i == 1) then ! First GLJ point
                      xxi = + gammaz(i,j,ispec) * jacobian(i,j,ispec)
                      rmass_inverse_elastic(1,iglob) = rmass_inverse_elastic(1,iglob) &
                         + xxi*wxglj(i)*wzgll(j)*rhol*jacobian(i,j,ispec) * (d_z_store(i,j,ispec_PML)* deltatover2)
                    else
                      rmass_inverse_elastic(1,iglob) = rmass_inverse_elastic(1,iglob) &
                         + coord(1,iglob)/(xiglj(i)+ONE)*wxglj(i)*wzgll(j)*rhol*jacobian(i,j,ispec) &
                         * (d_z_store(i,j,ispec_PML)* deltatover2)
                    endif
                  else ! not on the axis
                    rmass_inverse_elastic(1,iglob) = rmass_inverse_elastic(1,iglob) &
                         + coord(1,iglob)*wxgll(i)*wzgll(j)*rhol*jacobian(i,j,ispec) * (d_z_store(i,j,ispec_PML)* deltatover2)
                  endif
                else ! not axisym
                  rmass_inverse_elastic(1,iglob) = rmass_inverse_elastic(1,iglob) &
                       + wxgll(i)*wzgll(j)*rhol*jacobian(i,j,ispec) * (d_z_store(i,j,ispec_PML)* deltatover2)
                endif
                rmass_inverse_elastic(2,iglob) = rmass_inverse_elastic(1,iglob)
              endif
            endif ! Newmark

          else
            ! elastic no PML
            if (AXISYM) then
              if (is_on_the_axis(ispec)) then
                if (is_on_the_axis(ispec) .and. i == 1) then
                  ! First GLJ point
                  xxi = + gammaz(i,j,ispec) * jacobian(i,j,ispec)
                  rmass_inverse_elastic(1,iglob) = rmass_inverse_elastic(1,iglob) &
                      + xxi*wxglj(i)*wzgll(j)*rhol*jacobian(i,j,ispec)
                else
                  rmass_inverse_elastic(1,iglob) = rmass_inverse_elastic(1,iglob) &
                      + coord(1,iglob)/(xiglj(i)+ONE)*wxglj(i)*wzgll(j)*rhol*jacobian(i,j,ispec)
                endif
              else
                ! not on the axis
                rmass_inverse_elastic(1,iglob) = rmass_inverse_elastic(1,iglob) &
                    + coord(1,iglob)*wxgll(i)*wzgll(j)*rhol*jacobian(i,j,ispec)
              endif
            else
              ! not axisym
              rmass_inverse_elastic(1,iglob) = rmass_inverse_elastic(1,iglob) &
                      + wxgll(i)*wzgll(j)*rhol*jacobian(i,j,ispec)
            endif
            rmass_inverse_elastic(2,iglob) = rmass_inverse_elastic(1,iglob)
          endif

        else if (ispec_is_acoustic(ispec)) then
          ! for acoustic medium

          this_element_has_PML = .false.
          if (PML_BOUNDARY_CONDITIONS .and. ispec_is_PML(ispec)) this_element_has_PML = .true.

          if (this_element_has_PML) then
            ! PML
            ispec_PML = spec_to_PML(ispec)

            ! mass matrix contribution for PML
            if (region_CPML(ispec) == CPML_X_ONLY) then
              if (AXISYM) then   !! ABAB: This PML cannot be on the axis: it is a right PML
                rmass_inverse_acoustic(iglob) = rmass_inverse_acoustic(iglob) &
                     + coord(1,iglob)*wxgll(i)*wzgll(j)/ kappal_relaxed*jacobian(i,j,ispec) &
                       * (K_x_store(i,j,ispec_PML))
              else ! not axisym
                rmass_inverse_acoustic(iglob) = rmass_inverse_acoustic(iglob) &
                     + wxgll(i)*wzgll(j)/ kappal_relaxed*jacobian(i,j,ispec) &
                       * (K_x_store(i,j,ispec_PML))
              endif

            else if (region_CPML(ispec) == CPML_XZ) then
              if (AXISYM) then   !! ABAB: This corner cannot be on the axis
                rmass_inverse_acoustic(iglob) = rmass_inverse_acoustic(iglob) &
                     + coord(1,iglob)*wxgll(i)*wzgll(j)/ kappal_relaxed*jacobian(i,j,ispec) &
                       * (K_x_store(i,j,ispec_PML) * K_z_store(i,j,ispec_PML))
              else ! not axisym
                rmass_inverse_acoustic(iglob) = rmass_inverse_acoustic(iglob) &
                  + wxgll(i)*wzgll(j)/ kappal_relaxed*jacobian(i,j,ispec) &
                    * (K_x_store(i,j,ispec_PML) * K_z_store(i,j,ispec_PML))
              endif

            else if (region_CPML(ispec) == CPML_Z_ONLY) then
              if (AXISYM) then
                if (is_on_the_axis(ispec)) then
                  if (is_on_the_axis(ispec) .and. i == 1) then ! First GLJ point
                    xxi = + gammaz(i,j,ispec) * jacobian(i,j,ispec)
                    rmass_inverse_acoustic(iglob) = rmass_inverse_acoustic(iglob) &
                          + xxi*wxglj(i)*wzgll(j)/ kappal_relaxed*jacobian(i,j,ispec) &
                            * (K_z_store(i,j,ispec_PML))
                  else
                    rmass_inverse_acoustic(iglob) = rmass_inverse_acoustic(iglob) &
                          + coord(1,iglob)/(xiglj(i)+ONE)*wxglj(i)*wzgll(j)/kappal_relaxed*jacobian(i,j,ispec) &
                            * (K_z_store(i,j,ispec_PML))
                  endif
                else ! not on the axis
                  rmass_inverse_acoustic(iglob) = rmass_inverse_acoustic(iglob) &
                         + coord(1,iglob)*wxgll(i)*wzgll(j)/ kappal_relaxed*jacobian(i,j,ispec) &
                           * (K_z_store(i,j,ispec_PML))
                endif
              else ! not axisym
                rmass_inverse_acoustic(iglob) = rmass_inverse_acoustic(iglob) &
                     + wxgll(i)*wzgll(j)/ kappal_relaxed*jacobian(i,j,ispec) &
                       * (K_z_store(i,j,ispec_PML))

              endif
            endif

            ! adds additional Newmark term (dt/2 * C) to mass matrix for stabilization
            if (time_stepping_scheme == 1) then
              if (region_CPML(ispec) == CPML_X_ONLY) then
                if (AXISYM) then   !! ABAB: This PML cannot be on the axis: it is a right PML
                  rmass_inverse_acoustic(iglob) = rmass_inverse_acoustic(iglob) &
                       + coord(1,iglob)*wxgll(i)*wzgll(j)/ kappal_relaxed*jacobian(i,j,ispec) &
                         * (d_x_store(i,j,ispec_PML) * deltatover2)
                else ! not axisym
                  rmass_inverse_acoustic(iglob) = rmass_inverse_acoustic(iglob) &
                       + wxgll(i)*wzgll(j)/ kappal_relaxed*jacobian(i,j,ispec) &
                         * (d_x_store(i,j,ispec_PML) * deltatover2)
                endif

              else if (region_CPML(ispec) == CPML_XZ) then
                if (AXISYM) then   !! ABAB: This corner cannot be on the axis
                  rmass_inverse_acoustic(iglob) = rmass_inverse_acoustic(iglob) &
                       + coord(1,iglob)*wxgll(i)*wzgll(j)/ kappal_relaxed*jacobian(i,j,ispec) &
                         * ((d_x_store(i,j,ispec_PML)*k_z_store(i,j,ispec_PML) &
                           + d_z_store(i,j,ispec_PML)*k_x_store(i,j,ispec_PML)) * deltatover2)
                else ! not axisym
                  rmass_inverse_acoustic(iglob) = rmass_inverse_acoustic(iglob) &
                       + wxgll(i)*wzgll(j)/ kappal_relaxed*jacobian(i,j,ispec) &
                         * ((d_x_store(i,j,ispec_PML)*k_z_store(i,j,ispec_PML) &
                           + d_z_store(i,j,ispec_PML)*k_x_store(i,j,ispec_PML)) * deltatover2)
                endif

              else if (region_CPML(ispec) == CPML_Z_ONLY) then
                if (AXISYM) then
                  if (is_on_the_axis(ispec)) then
                    if (is_on_the_axis(ispec) .and. i == 1) then ! First GLJ point
                      xxi = + gammaz(i,j,ispec) * jacobian(i,j,ispec)
                      rmass_inverse_acoustic(iglob) = rmass_inverse_acoustic(iglob) &
                         + xxi*wxglj(i)*wzgll(j)/kappal_relaxed*jacobian(i,j,ispec) &
                           * (d_z_store(i,j,ispec_PML)* deltatover2)
                    else
                      rmass_inverse_acoustic(iglob) = rmass_inverse_acoustic(iglob) &
                         + coord(1,iglob)/(xiglj(i)+ONE)*wxglj(i)*wzgll(j)/kappal_relaxed*jacobian(i,j,ispec) &
                           * (d_z_store(i,j,ispec_PML)* deltatover2)
                    endif
                  else ! not on the axis
                    rmass_inverse_acoustic(iglob) = rmass_inverse_acoustic(iglob) &
                         + coord(1,iglob)*wxgll(i)*wzgll(j)/kappal_relaxed*jacobian(i,j,ispec) &
                           * (d_z_store(i,j,ispec_PML)* deltatover2)
                  endif
                else ! not axisym
                  rmass_inverse_acoustic(iglob) = rmass_inverse_acoustic(iglob) &
                       + wxgll(i)*wzgll(j)/kappal_relaxed*jacobian(i,j,ispec) &
                         * (d_z_store(i,j,ispec_PML)* deltatover2)
                endif
              endif
            endif ! Newmark

          else

            ! acoustic no PML
            if (AXISYM) then
              if (is_on_the_axis(ispec)) then
                if (is_on_the_axis(ispec) .and. i == 1) then
                  ! First GLJ point
                  xxi = + gammaz(i,j,ispec) * jacobian(i,j,ispec)
                  rmass_inverse_acoustic(iglob) = rmass_inverse_acoustic(iglob) &
                      + xxi*wxglj(i)*wzgll(j)*jacobian(i,j,ispec) / kappal_relaxed

                  if (ATTENUATION_VISCOACOUSTIC) then
                    ! loop over relaxation mechanisms
                    do i_sls = 1,N_SLS
                      phinu1 = 1.0
                      if (time_stepping_scheme > 1) phinu1 = phi_nu1(i,j,ispec,i_sls)
                      rmass_inverse_e1(iglob,i_sls) = rmass_inverse_e1(iglob,i_sls) &
                         + xxi*wxglj(i)*wzgll(j)*jacobian(i,j,ispec) / phinu1
                    enddo
                  endif

                else
                  rmass_inverse_acoustic(iglob) = rmass_inverse_acoustic(iglob) &
                      + coord(1,iglob)/(xiglj(i)+ONE)*wxglj(i)*wzgll(j)*jacobian(i,j,ispec) / kappal_relaxed

                  if (ATTENUATION_VISCOACOUSTIC) then
                    ! loop over relaxation mechanisms
                    do i_sls = 1,N_SLS
                      phinu1 = 1.
                      if (time_stepping_scheme > 1) phinu1 = phi_nu1(i,j,ispec,i_sls)
                      rmass_inverse_e1(iglob,i_sls) = rmass_inverse_e1(iglob,i_sls) &
                         + coord(1,iglob)/(xiglj(i)+ONE)*wxglj(i)*wzgll(j)*jacobian(i,j,ispec) / phinu1
                    enddo
                  endif

                endif
              else
                ! not on the axis
                rmass_inverse_acoustic(iglob) = rmass_inverse_acoustic(iglob) &
                    + coord(1,iglob)*wxgll(i)*wzgll(j)*jacobian(i,j,ispec) / kappal_relaxed

                if (ATTENUATION_VISCOACOUSTIC) then
                  ! loop over relaxation mechanisms
                  do i_sls = 1,N_SLS
                    phinu1 = 1.0
                    if (time_stepping_scheme > 1) phinu1 = phi_nu1(i,j,ispec,i_sls)
                    rmass_inverse_e1(iglob,i_sls) = rmass_inverse_e1(iglob,i_sls) &
                       + coord(1,iglob)*wxgll(i)*wzgll(j)*jacobian(i,j,ispec) / phinu1
                  enddo
                endif

              endif
            else
              ! not axisym
              rmass_inverse_acoustic(iglob) = rmass_inverse_acoustic(iglob) &
                   + wxgll(i)*wzgll(j)*jacobian(i,j,ispec) / kappal_relaxed

              if (ATTENUATION_VISCOACOUSTIC) then
                ! loop over relaxation mechanisms
                do i_sls = 1,N_SLS
                  phinu1 = 1.0
                  if (time_stepping_scheme > 1) phinu1 = phi_nu1(i,j,ispec,i_sls)
                  rmass_inverse_e1(iglob,i_sls) = rmass_inverse_e1(iglob,i_sls) &
                       + wxgll(i)*wzgll(j)*jacobian(i,j,ispec) / phinu1
                enddo
              endif

            endif

          endif
        else
          call stop_the_code('Invalid element type found in routine invert_mass_matrix_init()')
        endif
      enddo
    enddo
  enddo ! of do ispec = 1,nspec

  !
  !--- DK and Zhinan Xie: add C Delta_t / 2 contribution to the mass matrix
  !--- DK and Zhinan Xie: in the case of Clayton-Engquist absorbing boundaries;
  !--- DK and Zhinan Xie: see for instance the book of Hughes (1987) chapter 9.
  !--- DK and Zhinan Xie: IMPORTANT: note that this implies that we must have two different mass matrices,
  !--- DK and Zhinan Xie: one per component of the wave field i.e. one per spatial dimension.
  !--- DK and Zhinan Xie: This was also suggested by Jean-Paul Ampuero in 2003.
  !

  ! Stacey contribution for elastic medium
  if (STACEY_ABSORBING_CONDITIONS .and. time_stepping_scheme == 1) then
    ! Newmark scheme contribution to mass matrix
    call invert_mass_matrix_init_Stacey()
  endif

  end subroutine invert_mass_matrix_init

!
!-------------------------------------------------------------------------------------------------
!

  subroutine invert_mass_matrix_init_Stacey()

  use constants, only: IMAIN,CUSTOM_REAL,NGLLX,NGLLZ,ONE,TWO,TWO_THIRDS,FOUR_THIRDS, &
                       IEDGE1,IEDGE2,IEDGE3,IEDGE4

  use specfem_par, only: myrank,any_elastic,any_acoustic, &
                         rmass_inverse_elastic, &
                         rmass_inverse_acoustic, &
                         time_stepping_scheme, &
                         ibool,wxgll,wzgll,jacobian, &
                         ispec_is_elastic,ispec_is_acoustic, &
                         rho_vpstore,rho_vsstore, &
                         num_abs_boundary_faces,abs_boundary_ispec, &
                         deltatover2, &
                         codeabs,codeabs_corner, &
                         ibegin_edge1,iend_edge1,ibegin_edge3,iend_edge3, &
                         ibegin_edge4,iend_edge4,ibegin_edge2,iend_edge2, &
                         xix,xiz,gammaz,gammax, &
                         time_stepping_scheme,P_SV,STACEY_ABSORBING_CONDITIONS

  implicit none

  ! local parameter
  integer :: ispecabs,ibegin,iend,jbegin,jend,ispec,i,j,iglob

  ! material properties of the elastic medium
  real(kind=CUSTOM_REAL) :: rho_vp,rho_vs
  real(kind=CUSTOM_REAL) :: nx,nz,vx,vy,vz,vn,tx,ty,tz
  real(kind=CUSTOM_REAL) :: weight,xxi,zxi,xgamma,zgamma,jacobian1D

  ! check if anything to do
  if (.not. STACEY_ABSORBING_CONDITIONS) return
  if (time_stepping_scheme /= 1) return  ! only for Newmark time scheme

  ! user output
  if (myrank == 0) then
    write(IMAIN,*) "  adding Stacey contributions to mass matrix"
    call flush_IMAIN()
  endif

  ! elastic medium
  if (any_elastic) then

    do ispecabs = 1,num_abs_boundary_faces

      ispec = abs_boundary_ispec(ispecabs)

      if (ispec_is_elastic(ispec)) then

        !--- left absorbing boundary
        if (codeabs(IEDGE4,ispecabs)) then
          i = 1
          do j = 1,NGLLZ
            iglob = ibool(i,j,ispec)

            rho_vp = rho_vpstore(i,j,ispec)
            rho_vs = rho_vsstore(i,j,ispec)

            xgamma = - xiz(i,j,ispec) * jacobian(i,j,ispec)
            zgamma = + xix(i,j,ispec) * jacobian(i,j,ispec)
            jacobian1D = sqrt(xgamma**2 + zgamma**2)
            nx = - zgamma / jacobian1D
            nz = + xgamma / jacobian1D

            weight = jacobian1D * wzgll(j)

            ! Clayton-Engquist condition if elastic
            if (P_SV) then
              ! P_SV-case
              vx = deltatover2
              vz = deltatover2

              vn = nx * vx + nz * vz

              tx = rho_vp * vn * nx + rho_vs * (vx - vn * nx)
              tz = rho_vp * vn * nz + rho_vs * (vz - vn * nz)

              rmass_inverse_elastic(1,iglob) = rmass_inverse_elastic(1,iglob) + tx*weight
              rmass_inverse_elastic(2,iglob) = rmass_inverse_elastic(2,iglob) + tz*weight
            else
              ! SH-case
              vy = deltatover2
              ty = rho_vs * vy
              rmass_inverse_elastic(1,iglob) = rmass_inverse_elastic(1,iglob) + ty*weight
              ! ficticous for SH case, but to be save when inverting
              rmass_inverse_elastic(2,iglob) = rmass_inverse_elastic(1,iglob)
            endif
          enddo
        endif  !  end of left absorbing boundary

        !--- right absorbing boundary
        if (codeabs(IEDGE2,ispecabs)) then
          i = NGLLX
          do j = 1,NGLLZ
            iglob = ibool(i,j,ispec)

            ! for analytical initial plane wave for Bielak's conditions
            ! left or right edge, horizontal normal vector

            rho_vp = rho_vpstore(i,j,ispec)
            rho_vs = rho_vsstore(i,j,ispec)

            xgamma = - xiz(i,j,ispec) * jacobian(i,j,ispec)
            zgamma = + xix(i,j,ispec) * jacobian(i,j,ispec)
            jacobian1D = sqrt(xgamma**2 + zgamma**2)
            nx = + zgamma / jacobian1D
            nz = - xgamma / jacobian1D

            weight = jacobian1D * wzgll(j)

            ! Clayton-Engquist condition if elastic
            if (P_SV) then
              ! P_SV-case
              vx = deltatover2
              vz = deltatover2

              vn = nx * vx + nz * vz

              tx = rho_vp * vn * nx + rho_vs * (vx - vn * nx)
              tz = rho_vp * vn * nz + rho_vs * (vz - vn * nz)

              rmass_inverse_elastic(1,iglob) = rmass_inverse_elastic(1,iglob) + tx*weight
              rmass_inverse_elastic(2,iglob) = rmass_inverse_elastic(2,iglob) + tz*weight
            else
              ! SH-case
              vy = deltatover2
              ty = rho_vs * vy
              rmass_inverse_elastic(1,iglob) = rmass_inverse_elastic(1,iglob) + ty*weight
              ! ficticous for SH case, but to be save when inverting
              rmass_inverse_elastic(2,iglob) = rmass_inverse_elastic(1,iglob)
            endif
          enddo
        endif  !  end of right absorbing boundary

        !--- bottom absorbing boundary
        if (codeabs(IEDGE1,ispecabs)) then
          j = 1
          do i = 1,NGLLX
            ! exclude corners to make sure there is no contradiction on the normal
            ! for Stacey absorbing conditions but not for incident plane waves;
            ! thus subtract nothing i.e. zero in that case
            if ((codeabs_corner(1,ispecabs) .and. i == 1) .or. (codeabs_corner(2,ispecabs) .and. i == NGLLX)) cycle

            iglob = ibool(i,j,ispec)

            rho_vp = rho_vpstore(i,j,ispec)
            rho_vs = rho_vsstore(i,j,ispec)

            xxi = + gammaz(i,j,ispec) * jacobian(i,j,ispec)
            zxi = - gammax(i,j,ispec) * jacobian(i,j,ispec)
            jacobian1D = sqrt(xxi**2 + zxi**2)
            nx = + zxi / jacobian1D
            nz = - xxi / jacobian1D

            weight = jacobian1D * wxgll(i)

            ! Clayton-Engquist condition if elastic
            if (P_SV) then
              ! P_SV-case
              vx = deltatover2
              vz = deltatover2

              vn = nx * vx + nz * vz

              tx = rho_vp * vn * nx + rho_vs * (vx - vn * nx)
              tz = rho_vp * vn * nz + rho_vs * (vz - vn * nz)

              rmass_inverse_elastic(1,iglob) = rmass_inverse_elastic(1,iglob) + tx*weight
              rmass_inverse_elastic(2,iglob) = rmass_inverse_elastic(2,iglob) + tz*weight
            else
              ! SH-case
              vy = deltatover2
              ty = rho_vs * vy
              rmass_inverse_elastic(1,iglob) = rmass_inverse_elastic(1,iglob) + ty*weight
              ! ficticous for SH case, but to be save when inverting
              rmass_inverse_elastic(2,iglob) = rmass_inverse_elastic(1,iglob)
            endif
          enddo
        endif  !  end of bottom absorbing boundary

        !--- top absorbing boundary
        if (codeabs(IEDGE3,ispecabs)) then
          j = NGLLZ
          do i = 1,NGLLX
            ! exclude corners to make sure there is no contradiction on the normal
            ! for Stacey absorbing conditions but not for incident plane waves;
            ! thus subtract nothing i.e. zero in that case
            if ((codeabs_corner(3,ispecabs) .and. i == 1) .or. (codeabs_corner(4,ispecabs) .and. i == NGLLX)) cycle

            iglob = ibool(i,j,ispec)

            rho_vp = rho_vpstore(i,j,ispec)
            rho_vs = rho_vsstore(i,j,ispec)

            xxi = + gammaz(i,j,ispec) * jacobian(i,j,ispec)
            zxi = - gammax(i,j,ispec) * jacobian(i,j,ispec)
            jacobian1D = sqrt(xxi**2 + zxi**2)
            nx = - zxi / jacobian1D
            nz = + xxi / jacobian1D

            weight = jacobian1D * wxgll(i)

            ! Clayton-Engquist condition if elastic
            if (P_SV) then
              ! P_SV-case
              vx = deltatover2
              vz = deltatover2

              vn = nx * vx + nz * vz

              tx = rho_vp * vn * nx + rho_vs * (vx - vn * nx)
              tz = rho_vp * vn * nz + rho_vs * (vz - vn * nz)

              rmass_inverse_elastic(1,iglob) = rmass_inverse_elastic(1,iglob) + tx*weight
              rmass_inverse_elastic(2,iglob) = rmass_inverse_elastic(2,iglob) + tz*weight
            else
              ! SH-case
              vy = deltatover2
              ty = rho_vs * vy
              rmass_inverse_elastic(1,iglob) = rmass_inverse_elastic(1,iglob) + ty*weight
              ! ficticous for SH case, but to be save when inverting
              rmass_inverse_elastic(2,iglob) = rmass_inverse_elastic(1,iglob)
            endif
          enddo
        endif  !  end of top absorbing boundary
      endif ! ispec_is_elastic
    enddo

  endif ! any_elastic

  ! acoustic elements
  if (any_acoustic) then

    do ispecabs = 1,num_abs_boundary_faces

      ispec = abs_boundary_ispec(ispecabs)

      ! Sommerfeld condition if acoustic
      if (ispec_is_acoustic(ispec)) then

        !--- left absorbing boundary
        if (codeabs(IEDGE4,ispecabs)) then
          i = 1
          jbegin = ibegin_edge4(ispecabs)
          jend = iend_edge4(ispecabs)
          do j = jbegin,jend
            iglob = ibool(i,j,ispec)
            rho_vp = rho_vpstore(i,j,ispec)

            xgamma = - xiz(i,j,ispec) * jacobian(i,j,ispec)
            zgamma = + xix(i,j,ispec) * jacobian(i,j,ispec)
            jacobian1D = sqrt(xgamma**2 + zgamma**2)
            weight = jacobian1D * wzgll(j)

            rmass_inverse_acoustic(iglob) = rmass_inverse_acoustic(iglob) + deltatover2*weight/rho_vp
          enddo
        endif  !  end of left absorbing boundary

        !--- right absorbing boundary
        if (codeabs(IEDGE2,ispecabs)) then
          i = NGLLX
          jbegin = ibegin_edge2(ispecabs)
          jend = iend_edge2(ispecabs)
          do j = jbegin,jend
            iglob = ibool(i,j,ispec)
            rho_vp = rho_vpstore(i,j,ispec)

            xgamma = - xiz(i,j,ispec) * jacobian(i,j,ispec)
            zgamma = + xix(i,j,ispec) * jacobian(i,j,ispec)
            jacobian1D = sqrt(xgamma**2 + zgamma**2)
            weight = jacobian1D * wzgll(j)

            rmass_inverse_acoustic(iglob) = rmass_inverse_acoustic(iglob) + deltatover2*weight/rho_vp
          enddo
        endif  !  end of right absorbing boundary

        !--- bottom absorbing boundary
        if (codeabs(IEDGE1,ispecabs)) then
          j = 1
          ibegin = ibegin_edge1(ispecabs)
          iend = iend_edge1(ispecabs)
          ! exclude corners to make sure there is no contradiction on the normal
          if (codeabs_corner(1,ispecabs)) ibegin = 2
          if (codeabs_corner(2,ispecabs)) iend = NGLLX-1
          do i = ibegin,iend
            iglob = ibool(i,j,ispec)
            rho_vp = rho_vpstore(i,j,ispec)

            xxi = + gammaz(i,j,ispec) * jacobian(i,j,ispec)
            zxi = - gammax(i,j,ispec) * jacobian(i,j,ispec)
            jacobian1D = sqrt(xxi**2 + zxi**2)
            weight = jacobian1D * wxgll(i)

            rmass_inverse_acoustic(iglob) = rmass_inverse_acoustic(iglob) + deltatover2*weight/rho_vp
          enddo
        endif  !  end of bottom absorbing boundary

        !--- top absorbing boundary
        if (codeabs(IEDGE3,ispecabs)) then
          j = NGLLZ
          ibegin = ibegin_edge3(ispecabs)
          iend = iend_edge3(ispecabs)
          ! exclude corners to make sure there is no contradiction on the normal
          if (codeabs_corner(3,ispecabs)) ibegin = 2
          if (codeabs_corner(4,ispecabs)) iend = NGLLX-1
          do i = ibegin,iend
            iglob = ibool(i,j,ispec)
            rho_vp = rho_vpstore(i,j,ispec)

            xxi = + gammaz(i,j,ispec) * jacobian(i,j,ispec)
            zxi = - gammax(i,j,ispec) * jacobian(i,j,ispec)
            jacobian1D = sqrt(xxi**2 + zxi**2)
            weight = jacobian1D * wxgll(i)

            rmass_inverse_acoustic(iglob) = rmass_inverse_acoustic(iglob) + deltatover2*weight/rho_vp
          enddo
        endif  !  end of top absorbing boundary
      endif ! ispec_is_acoustic
    enddo

  endif ! any_acoustic

  end subroutine invert_mass_matrix_init_Stacey

!
!-------------------------------------------------------------------------------------------------
!

  subroutine invert_mass_matrix()

! inverts the global mass matrix

  use specfem_par, only: myrank,any_elastic,any_acoustic,any_poroelastic, &
                                rmass_inverse_elastic, &
                                rmass_inverse_acoustic, &
                                rmass_inverse_e1,ATTENUATION_VISCOACOUSTIC, &
                                rmass_s_inverse_poroelastic, &
                                rmass_w_inverse_poroelastic
  implicit none
  include 'constants.h'

  if (myrank == 0) then
    write(IMAIN,*) "  inverting mass matrices"
    write(IMAIN,*)
    call flush_IMAIN()
  endif

! fill mass matrix with fictitious non-zero values to make sure it can be inverted globally
! (this can happen when some degrees of freedom have been removed from some of the global arrays)
  if (any_elastic) then
    where(rmass_inverse_elastic <= 0._CUSTOM_REAL) rmass_inverse_elastic = 1._CUSTOM_REAL
  endif

  if (any_poroelastic) then
    where(rmass_s_inverse_poroelastic <= 0._CUSTOM_REAL) rmass_s_inverse_poroelastic = 1._CUSTOM_REAL
    where(rmass_w_inverse_poroelastic <= 0._CUSTOM_REAL) rmass_w_inverse_poroelastic = 1._CUSTOM_REAL
  endif

  if (any_acoustic) then
    where(rmass_inverse_acoustic <= 0._CUSTOM_REAL) rmass_inverse_acoustic = 1._CUSTOM_REAL
    if (ATTENUATION_VISCOACOUSTIC) where(abs(rmass_inverse_e1) <= 0._CUSTOM_REAL) rmass_inverse_e1 = 1._CUSTOM_REAL
  endif

! compute the inverse of the mass matrix
  if (any_elastic) then
    rmass_inverse_elastic(:,:) = 1._CUSTOM_REAL / rmass_inverse_elastic(:,:)
  endif

  if (any_poroelastic) then
    rmass_s_inverse_poroelastic(:) = 1._CUSTOM_REAL / rmass_s_inverse_poroelastic(:)
    rmass_w_inverse_poroelastic(:) = 1._CUSTOM_REAL / rmass_w_inverse_poroelastic(:)
  endif

  if (any_acoustic) then
    rmass_inverse_acoustic(:) = 1._CUSTOM_REAL / rmass_inverse_acoustic(:)
    if (ATTENUATION_VISCOACOUSTIC) rmass_inverse_e1(:,:) = 1._CUSTOM_REAL / rmass_inverse_e1(:,:)
  endif

  end subroutine invert_mass_matrix


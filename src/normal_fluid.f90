!>normal fluid component in the equation of motion, if the filament acts as a vortex
!>velocity enters as \f$\mathbf{u}=\alpha \mathbf{s}' \times (\mathbf{u}_\mathrm{n}-\mathbf{u}_\mathrm{s})+
!>\alpha' \mathbf{s}' \times [\mathbf{s}' \times (\mathbf{u}_\mathrm{n}-\mathbf{u}_\mathrm{s})]\f$
!>if the filament is a material line then the normaly velocity is used directly.
!>for further information on the normal fluid options see \ref NF
module normal_fluid
  use cdata
  use general
  use ksmodel
    !parameters used in get_normal_fluid
    real, parameter, private :: abc_A=1., abc_B=1., abc_C=1.
    real, private :: norm_k
    real, private :: normal_direction(3) !used  by random_xflow
    real, private :: xflow_noise=0. !used by noisy xflow
    real, private :: urms_norm
    real, private :: t_change=-100. !a little less than 0!
    !>normal fluid mesh - all grid based normal velocities use this (e.g. Navier Stokes future)
    !>@param x the position on the grid
    !>@param u the velocity
    !>@param v a scalar used in the compressible flow case
    !>@param div the divergence of the velocity field at x
    type norm_fluid_grid
      private
      real :: x(3)
      real :: u(3)
      real :: v
      real :: div 
    end type
    !use the abbreviation nfm (normal fluid mesh)
    !>the size of the normal fluid mesh, put in run.in soon
    integer, private, parameter :: nfm_size=64 
    real, private :: nfm_res, nfm_inv_res !resolution/inv resolution of normal fluid mesh
    !>the normal fluid mesh
    type(norm_fluid_grid), allocatable, private :: nfm(:,:,:)
    contains 
    !************************************************************
    !>setup everything needed to use a normal fluid
    subroutine setup_normal_fluid
      !in here we print to file the timescale of the flow
      implicit none
      norm_k=2.*pi/box_size !wavenumber used in a number of normal fluid
      write(*,*) 'normal fluid velocity field is: ', trim(normal_velocity)
      select case(normal_velocity)
        case('xflow')
          urms_norm=norm_vel_xflow
          write(*,'(a,f6.3)') ' u(x)=', norm_vel_xflow
          open(unit=77,file='./data/normal_timescale.log',status='replace')
            write(77,*) box_size/norm_vel_xflow !time-taken to cross box
          close(77)
        case('noisy_xflow')
          urms_norm=norm_vel_xflow
          write(*,'(a,f6.3,a)') ' u(x)=', norm_vel_xflow, ' +noise'
          write(*,'(a,i6.6)') ' noise changed every ',normal_fluid_freq, ' timesteps'
          open(unit=77,file='./data/normal_timescale.log',status='replace')
            write(77,*) box_size/norm_vel_xflow !time-taken to cross box
          close(77)
        case('random_xflow')
          urms_norm=norm_vel_xflow
          write(*,'(a,f6.3)') ' random counterflow |u|=', norm_vel_xflow
          write(*,'(a,i6.6)') ' flow direction will be changed every ',normal_fluid_freq, ' timesteps'
          open(unit=77,file='./data/normal_timescale.log',status='replace')
            write(77,*) box_size/norm_vel_xflow !time-taken to cross box
          close(77)  
        case('ABC')
          write(*,'(a,f6.3,a,f6.3,a,f6.3)') ' A=', abc_A, ' B=', abc_B, ' C=', abc_C
          call setup_gen_normalf !normal_fluid.mod
          open(unit=77,file='./data/normal_timescale.log',status='replace')
            write(77,*) box_size/urms_norm !size of box scaled by urms
          close(77)
        case('taylor-green')
          call setup_gen_normalf !normal_fluid.mod
          open(unit=77,file='./data/normal_timescale.log',status='replace')
            write(77,*) box_size/urms_norm !size of box scaled by urms
          close(77)
        case('potential_vortex')
          call setup_gen_normalf !normal_fluid.mod
          open(unit=77,file='./data/normal_timescale.log',status='replace')
            write(77,*) box_size/urms_norm !size of box scaled by urms
          close(77)
        case('expand','expand_rot','collapse_rot')
          call setup_gen_normalf !normal_fluid.mod
          open(unit=77,file='./data/normal_timescale.log',status='replace')
            write(77,*) box_size/urms_norm !size of box scaled by urms
          close(77)
          !the normal fluid velocity is not divergence free
          nf_compressible=.true.
        case('shear')
          call setup_gen_normalf !normal_fluid.mod
          open(unit=77,file='./data/normal_timescale.log',status='replace')
            write(77,*) box_size/urms_norm !size of box scaled by urms
          close(77)
        case('sod')
          call setup_gen_normalf !normal_fluid.mod
          open(unit=77,file='./data/normal_timescale.log',status='replace')
            write(77,*) box_size/urms_norm !size of box scaled by urms
          close(77)
        case('galloway-proctor')
          call setup_gen_normalf !normal_fluid.mod
          open(unit=77,file='./data/normal_timescale.log',status='replace')
            write(77,*) box_size/urms_norm !size of box scaled by urms
          close(77)
        case('KS')
          call setup_KS !ksmodel.mod
          call print_KS_Mesh !normal_fluid.mod
          !Normal vel timescale written in setup_KS (line 109)
        case('compressible')
          if (periodic_bc) then 
            write(*,'(a,i4.2,a)') ' creating gradient of a random field  on a', nfm_size,'^3 mesh'
            call setup_compressible !normal_fluid.mod
            open(unit=77,file='./data/normal_timescale.log',status='replace')
              write(77,*) box_size/urms_norm !size of box scaled by urms
            close(77)
          else
            call fatal_error('normal_fluid.mod','comrpressible v needs periodic b.c.')
          end if
        !case('nf_macro_ring') %nothing to do yet
      end select
      write(*,'(a,f6.4,a,f6.4)') ' mutual friction coefficients alpha=',alpha(1),' alpha`=',alpha(2) 
      if (normal_fluid_cutoff<1000.) then
        write(*,'(a,f6.3)') ' normal fluid is turned off when t=',normal_fluid_cutoff 
      end if
      write(*,'(a,f8.4)') ' normal fluid rms velocity is: ', urms_norm
      write(*,'(a)') ' normal fluid timescale printed to ./data/normal_timescale.log'
    end subroutine
    !************************************************************
    !>get the velocity (u) of the normal fluid at a position (x)
    !>see the normal fluid page for more information
    subroutine get_normal_velocity(x,u)
      implicit none
      real, intent(IN) :: x(3) !position of the particle
      real, intent(OUT) :: u(3) !velocity at x
      real :: r, phi, theta !used to convert to polar coords
      real :: u_r, u_theta !used to convert to polar coords
      integer :: peri, perj, perk !used to loop in periodic cases
      u=0. ! a safety check , 0 the field before we begin!
      select case(normal_velocity)
        case('zero')
          u=0. ! no flow
        case('xflow')
          u=0. ; u(1)=norm_vel_xflow !flow in the x direction
        case('noisy_xflow')
          !do we need to generate a new noise?
          if ((mod(itime,normal_fluid_freq)==0).or.(itime==1)) then
            if (t>t_change) then !by using t_change we only
              !change the noise once, not for every point
              xflow_noise=rnorm(0.,(norm_vel_xflow/10.)**2)
              print*, xflow_noise
              open(unit=37,file='./data/noisy_xflow.log',position='append')
                write(37,*) t, norm_vel_xflow+xflow_noise
              close(37)
              t_change=t
            end if
          end if
          u=0. ; u(1)=norm_vel_xflow+xflow_noise
        case('random_xflow')
          !do we need to generate a new direction?
          if ((mod(itime,normal_fluid_freq)==0).or.(itime==1)) then
            if (t>t_change) then
              call random_number(normal_direction)
              normal_direction=normal_direction*2.-1.
              normal_direction=normal_direction/sqrt(dot_product(normal_direction,normal_direction))
              open(unit=37,file='./data/random_xflow.log',position='append')
                write(37,*) t, normal_direction
              close(37)
              t_change=t
            end if
          end if
          u=norm_vel_xflow*normal_direction
        case('ABC')
          !commonly used toy model - turbulence/dynamo
          u(1)=abc_B*cos(norm_k*x(2))+abc_C*sin(norm_k*x(3))
          u(2)=abc_C*cos(norm_k*x(3))+abc_A*sin(norm_k*x(1))
          u(3)=abc_A*cos(norm_k*x(1))+abc_B*sin(norm_k*x(2))
        case('potential_vortex')
          u(1)=-x(2)/(x(1)**2+x(2)**2+(box_size/80)**2)
          u(2)=x(1)/(x(1)**2+x(2)**2+(box_size/80)**2)
          u(3)=0.
          if (periodic_bc) then
            do peri=-1,1 ; do perj=-1,1 
              if (peri==0.and.perj==0) cycle
              u(1)=u(1)-(x(2)-perj*box_size)/&
              ((x(1)-peri*box_size)**2+(x(2)-perj*box_size)**2+(box_size/80)**2)
              u(2)=u(2)+(x(1)-peri*box_size)/&
              ((x(1)-peri*box_size)**2+(x(2)-perj*box_size)**2+(box_size/80)**2)
            end do ; end do
          end if
          u=u*(box_size/40)
        case('taylor-green')
          !The Taylor-Green Vortex
          !u(1)=sin(norm_k*x(1))*cos(norm_k*x(2))*cos(norm_k*x(3))
          !u(2)=-cos(norm_k*x(1))*sin(norm_k*x(2))*cos(norm_k*x(3))
          !u(3)=0.
          !TG vorticity field - commented out but useful!
          u(1)=-cos(norm_k*x(1))*sin(norm_k*x(2))*sin(norm_k*x(3))
          u(2)=-sin(norm_k*x(1))*cos(norm_k*x(2))*sin(norm_k*x(3))
          u(3)=2.*sin(norm_k*x(1))*sin(norm_k*x(2))*cos(norm_k*x(3))
        case('shear')
          u=0.
          u(1)=exp(-(6*x(3)/box_size)**2)
        case('expand')
          u=0.
          r=sqrt(x(1)**2+x(2)**2+x(3)**2)
          theta=acos(x(3)/r)
          phi=atan2(x(2),x(1))
          u_r=r
          u(1)=sin(theta)*cos(phi)*u_r
          u(2)=sin(theta)*sin(phi)*u_r
          u(3)=cos(theta)*u_r
        case('expand_rot')
          u=0.
          r=sqrt(x(1)**2+x(2)**2+x(3)**2)
          theta=acos(x(3)/r)
          phi=atan2(x(2),x(1))
          u_r=r
          u_theta=1./(0.5+r)
          u(1)=sin(theta)*cos(phi)*u_r-sin(phi)*u_theta
          u(2)=sin(theta)*sin(phi)*u_r+cos(phi)*u_theta
          u(3)=cos(theta)*u_r
        case('collapse_rot')
          u=0.
          r=sqrt(x(1)**2+x(2)**2+x(3)**2)
          theta=acos(x(3)/r)
          phi=atan2(x(2),x(1))
          u_r=-r
          u_theta=1./(0.5+r)
          u(1)=sin(theta)*cos(phi)*u_r-sin(phi)*u_theta
          u(2)=sin(theta)*sin(phi)*u_r+cos(phi)*u_theta
          u(3)=cos(theta)*u_r
        case('sod')
          if (x(1)<box_size/3.) then
            u(1)=0.5*tanh(10.*(x(1)+box_size/5.)/box_size)+0.5
          else 
            u(1)=0.
          end if
          u(2)=0. ; u(3)=0.
        case('galloway-proctor')
          u(1)=-sin(norm_k*x(2)+cos(t))
          u(2)=-cos(norm_k*x(1)+sin(t))
          u(3)=sin(norm_k*x(1)+sin(t))+cos(norm_k*x(2)+cos(t))
        case('KS')
          !multi-scale model of turbulence
          call get_KS_flow(x,u)
        case('compressible')
          !compressible flow on a mesh, needs interpolation
          call nfm_interpolation(x,u)
        case('nf_macro_ring')
          call get_nf_macro_ring(x,u) !normal_fluid.mod
        case default
          call fatal_error('normal_fluid.mod:get_normal_fluid', &
          'correct parameter for normal_veloctity not set')
      end select
    end subroutine
    !************************************************************
    !>get the divergence of the velocity (divu) of the normal fluid 
    !!at a position (x)
    subroutine get_normal_divu(x,divu)
      implicit none
      real, intent(IN) :: x(3) !position of the particle
      real, intent(OUT) :: divu !velocity at x
      select case(normal_velocity)
        case('expand','expand_rot')
          divu=3.
          !divu=2.
        case('collapse_rot')
          divu=-3.
        case default
          divu=0.
      end select
    end subroutine
    !**********************************************************
    !>(linear) interpolation of the normal fluid velocity from a mesh
    !>needed for certain selections of velocity
    subroutine nfm_interpolation(x,u)
      implicit none
      real, intent(IN) :: x(3) !position
      real, intent(OUT) :: u(3) !velocity
      real :: dx, dy, dz 
      integer :: i !for looping
      integer :: ix=1, iy=1, iz=1
      integer :: midpt
      midpt=nfm_size/2
      !find the closest meshpoints

      do i=1, nfm_size-1
        if ((x(1)>nfm(midpt,midpt,i)%x(1)).and.(x(1)<nfm(midpt,midpt,i+1)%x(1))) ix=i
        if ((x(2)>nfm(midpt,i,midpt)%x(2)).and.(x(2)<nfm(midpt,i+1,midpt)%x(2))) iy=i
        if ((x(3)>nfm(i,midpt,midpt)%x(3)).and.(x(3)<nfm(i+1,midpt,midpt)%x(3))) iz=i
      end do

      !find normalised disatances in all three spacial dimensions
      dx=abs(x(1)-nfm(iz,iy,ix)%x(1))/nfm_res
      dy=abs(x(2)-nfm(iz,iy,ix)%x(2))/nfm_res
      dz=abs(x(3)-nfm(iz,iy,ix)%x(3))/nfm_res

      !trilinear interpolation
      u=(1.-dx)*(1.-dy)*(1.-dz)*nfm(iz,iy,ix)%u+&
           dx*(1.-dy)*(1.-dz)*nfm(iz,iy,ix+1)%u+&
           (1.-dx)*dy*(1.-dz)*nfm(iz,iy+1,ix)%u+&
           (1.-dx)*(1.-dy)*dz*nfm(iz+1,iy,ix)%u+&
              dx*dy*(1.-dz)*nfm(iz,iy+1,ix+1)%u+&
              dx*(1.-dy)*dz*nfm(iz+1,iy,ix+1)%u+&
              (1.-dx)*dy*dz*nfm(iz+1,iy+1,ix)%u+&
                 dx*dy*dz*nfm(iz+1,iy+1,ix+1)%u
    end subroutine
    !**********************************************************
    !>(linear) interpolation of the normal fluid divergence of vel field
    !>needed for certain selections of velocity
    subroutine nfm_compressibility(x,divu)
      implicit none
      real, intent(IN) :: x(3) !position
      real, intent(OUT) :: divu(3) !velocity
      real :: dx, dy, dz 
      integer :: i !for looping
      integer :: ix=1, iy=1, iz=1
      integer :: midpt
      midpt=nfm_size/2
      !find the closest meshpoints

      do i=1, nfm_size-1
        if ((x(1)>nfm(midpt,midpt,i)%x(1)).and.(x(1)<nfm(midpt,midpt,i+1)%x(1))) ix=i
        if ((x(2)>nfm(midpt,i,midpt)%x(2)).and.(x(2)<nfm(midpt,i+1,midpt)%x(2))) iy=i
        if ((x(3)>nfm(i,midpt,midpt)%x(3)).and.(x(3)<nfm(i+1,midpt,midpt)%x(3))) iz=i
      end do

      !find normalised disatances in all three spacial dimensions
      dx=abs(x(1)-nfm(iz,iy,ix)%x(1))/nfm_res
      dy=abs(x(2)-nfm(iz,iy,ix)%x(2))/nfm_res
      dz=abs(x(3)-nfm(iz,iy,ix)%x(3))/nfm_res

      !trilinear interpolation
      divu=(1.-dx)*(1.-dy)*(1.-dz)*nfm(iz,iy,ix)%div+&
           dx*(1.-dy)*(1.-dz)*nfm(iz,iy,ix+1)%div+&
           (1.-dx)*dy*(1.-dz)*nfm(iz,iy+1,ix)%div+&
           (1.-dx)*(1.-dy)*dz*nfm(iz+1,iy,ix)%div+&
              dx*dy*(1.-dz)*nfm(iz,iy+1,ix+1)%div+&
              dx*(1.-dy)*dz*nfm(iz+1,iy,ix+1)%div+&
              (1.-dx)*dy*dz*nfm(iz+1,iy+1,ix)%div+&
                 dx*dy*dz*nfm(iz+1,iy+1,ix+1)%div
    end subroutine
    !**********************************************************
    !>setup a compressible velocity field by taking the gradient 
    !>of a random scalar field
    subroutine setup_compressible
      implicit none
      real :: u_rms
      integer :: i, j, k
      integer :: im, jm, km, ip, jp, kp
      !print dimensions to file for matlab
      open(unit=77,file='./data/nfm_dims.log',status='replace')
        write(77,*) nfm_size
      close(77)
      allocate(nfm(nfm_size,nfm_size,nfm_size))
      nfm_res=(real(box_size)/nfm_size)
      nfm_inv_res=1./nfm_res
      do k=1, nfm_size  ; do j=1, nfm_size ; do i=1, nfm_size
        nfm(k,j,i)%x(1)=nfm_res*real(2*i-1)/2.-(box_size/2.)
        nfm(k,j,i)%x(2)=nfm_res*real(2*j-1)/2.-(box_size/2.)
        nfm(k,j,i)%x(3)=nfm_res*real(2*k-1)/2.-(box_size/2.)
        !first set the scalar field
        call random_number(nfm(k,j,i)%v)
        nfm(k,j,i)%v=nfm(k,j,i)%v*2.-1. ; nfm(k,j,i)%v=0.01*nfm(k,j,i)%v
      end do ; end do ; end do
      ! now we must take the gradient of this
      u_rms=0. !0 the root mean squared velocity
      do k=1, nfm_size  ; do j=1, nfm_size ; do i=1, nfm_size
        if (k==1) then !PERIODICITY
          kp=k+1 ; km=nfm_size
        else if (k==nfm_size) then
          kp=1 ; km=k-1
        else
          kp=k+1 ; km=k-1
        end if 
        if (j==1) then !PERIODICITY
          jp=j+1 ; jm=nfm_size
        else if (j==nfm_size) then
          jp=1 ; jm=j-1
        else
          jp=j+1 ; jm=j-1
        end if 
        if (i==1) then !PERIODICITY
          ip=i+1 ; im=nfm_size
        else if (i==nfm_size) then
          ip=1 ; im=i-1
        else
          ip=i+1 ; im=i-1
        end if
        !get the velocity field - gradient of scalar field
        nfm(k,j,i)%u(1)=(nfm(k,j,ip)%v-nfm(k,j,im)%v)*nfm_inv_res
        nfm(k,j,i)%u(2)=(nfm(k,jp,i)%v-nfm(k,jm,i)%v)*nfm_inv_res
        nfm(k,j,i)%u(3)=(nfm(kp,j,i)%v-nfm(km,j,i)%v)*nfm_inv_res
        u_rms=u_rms+(nfm(k,j,i)%u(1)**2+nfm(k,j,i)%u(2)**2+nfm(k,j,i)%u(3)**2)
      end do ; end do ; end do
      u_rms=sqrt(u_rms/(nfm_size**3))
      !now we normalise this field by u_rms
      nfm%u(1)=nfm%u(1)/u_rms ; nfm%u(2)=nfm%u(2)/u_rms ; nfm%u(3)=nfm%u(3)/u_rms
      urms_norm=1.!urms_norm must be 1 as we have scaled it to be!
      ! calculate the divergence of this field
      do k=1, nfm_size  ; do j=1, nfm_size ; do i=1, nfm_size
        if (k==1) then !PERIODICITY
          kp=k+1 ; km=nfm_size
        else if (k==nfm_size) then
          kp=1 ; km=k-1
        else
          kp=k+1 ; km=k-1
        end if 
        if (j==1) then !PERIODICITY
          jp=j+1 ; jm=nfm_size
        else if (j==nfm_size) then
          jp=1 ; jm=j-1
        else
          jp=j+1 ; jm=j-1
        end if 
        if (i==1) then !PERIODICITY
          ip=i+1 ; im=nfm_size
        else if (i==nfm_size) then
          ip=1 ; im=i-1
        else
          ip=i+1 ; im=i-1
        end if
        !take the gradient of a random scalar field
        nfm(k,j,i)%div=(nfm(k,j,ip)%u(1)-nfm(k,j,im)%u(1))*nfm_inv_res + &
                                (nfm(k,jp,i)%u(2)-nfm(k,jm,i)%u(2))*nfm_inv_res + &
                                (nfm(kp,j,i)%u(3)-nfm(km,j,i)%u(3))*nfm_inv_res
      end do ; end do ; end do
      write(*,'(a)') ' velocity field calculated, printing to ./data/compressible_mesh.dat'
      open(unit=92,file='./data/compressible_mesh.dat',form='unformatted',status='replace',access='stream')
        write(92) nfm(nfm_size/2,nfm_size/2,1:nfm_size)%x(1)
        write(92) nfm(:,:,:)%v
        write(92) nfm(:,:,:)%div
        write(92) nfm(:,:,:)%u(1)
        write(92) nfm(:,:,:)%u(2)
        write(92) nfm(:,:,:)%u(3)
      close(92)
    end subroutine 
    !**********************************************************
    !>set up simple normal fluid models (ones with an analytic form)
    !>and print this field (discretized on a cubic mesh) to a binary file
    subroutine setup_gen_normalf
      implicit none
      integer :: i, j, k
      !print dimensions to file for matlab
      open(unit=77,file='./data/nfm_dims.log',status='replace')
        write(77,*) nfm_size
      close(77)
      allocate(nfm(nfm_size,nfm_size,nfm_size))
      nfm_res=(real(box_size)/nfm_size)
      nfm_inv_res=1./nfm_res
      do k=1, nfm_size  ; do j=1, nfm_size ; do i=1, nfm_size
        nfm(k,j,i)%x(1)=nfm_res*real(2*i-1)/2.-(box_size/2.)
        nfm(k,j,i)%x(2)=nfm_res*real(2*j-1)/2.-(box_size/2.)
        nfm(k,j,i)%x(3)=nfm_res*real(2*k-1)/2.-(box_size/2.)
      end do ; end do ; end do
      urms_norm=0. !0 the root mean squared velocity
      do k=1, nfm_size  ; do j=1, nfm_size ; do i=1, nfm_size
        !get the velocity field - shearing wave
        call get_normal_velocity(nfm(k,j,i)%x,nfm(k,j,i)%u)
        urms_norm=urms_norm+(nfm(k,j,i)%u(1)**2+nfm(k,j,i)%u(2)**2+nfm(k,j,i)%u(3)**2)
      end do ; end do ; end do
      urms_norm=sqrt(urms_norm/(nfm_size**3))
      write(*,'(a)') ' velocity field calculated, printing to ./data/norm_init_mesh.dat'
      open(unit=92,file='./data/norm_init_mesh.dat',form='unformatted',status='replace',access='stream')
        write(92) nfm(nfm_size/2,nfm_size/2,1:nfm_size)%x(1)
        write(92) nfm(:,:,:)%u(1)
        write(92) nfm(:,:,:)%u(2)
        write(92) nfm(:,:,:)%u(3)
      close(92)
    end subroutine
    !**********************************************************
    !>print the KS velocity field (on a cubic mesh) to a binary file
    subroutine print_KS_Mesh
      implicit none
      integer :: i, j, k
      !print dimensions to file for matlab
      open(unit=77,file='./data/nfm_dims.log',status='replace')
        write(77,*) nfm_size
      close(77)
      allocate(nfm(nfm_size,nfm_size,nfm_size))
      nfm_res=(real(box_size)/nfm_size)
      nfm_inv_res=1./nfm_res
      do k=1, nfm_size  ; do j=1, nfm_size ; do i=1, nfm_size
        nfm(k,j,i)%x(1)=nfm_res*real(2*i-1)/2.-(box_size/2.)
        nfm(k,j,i)%x(2)=nfm_res*real(2*j-1)/2.-(box_size/2.)
        nfm(k,j,i)%x(3)=nfm_res*real(2*k-1)/2.-(box_size/2.)
      end do ; end do ; end do
      urms_norm=0. !0 the root mean squared velocity
      do k=1, nfm_size  ; do j=1, nfm_size ; do i=1, nfm_size
        !get the velocity field - ABC flow
        call get_KS_flow(nfm(k,j,i)%x,nfm(k,j,i)%u)       
        urms_norm=urms_norm+(nfm(k,j,i)%u(1)**2+nfm(k,j,i)%u(2)**2+nfm(k,j,i)%u(3)**2)
      end do ; end do ; end do
      urms_norm=sqrt(urms_norm/(nfm_size**3))
      write(*,'(a)') ' velocity field calculated, printing to ./data/KS_mesh.dat'
      open(unit=92,file='./data/KS_mesh.dat',form='unformatted',status='replace',access='stream')
        write(92) nfm(nfm_size/2,nfm_size/2,1:nfm_size)%x(1)
        write(92) nfm(:,:,:)%u(1)
        write(92) nfm(:,:,:)%u(2)
        write(92) nfm(:,:,:)%u(3)
      close(92)
    end subroutine
    !************************************************************
    subroutine get_nf_macro_ring(x,u)
      use cdata
      use general      
      implicit none
      integer :: i,actual_line_count
      real,dimension(3) :: cov,x,u  ! centre of vorticity
      real :: phi  ! angle between y-axis and 'hat'-axis
      real :: cov_y_hat,pv_y_hat  ! y_hat-coord of cov and pv
      real :: delta_x,delta_y1,delta_y2,theta1,theta2,r1,r2
      real :: u_theta1,u_theta2,u_y_hat  ! velocities in 'hat' plane

      ! Find 'centre of vorticity' 
      do i=1,3
        cov(i)=sum(f(:)%x(i))/pcount
      end do
    
	  ! Find phi for each vortex point
	  phi=atan( (x(3)-cov(3)) / (x(2)-cov(2)) )
	
	  ! Find theta1 and theta2 for each vortex point
	  cov_y_hat=cov(2)/cos(phi)
	  pv_y_hat=x(2)/cos(phi)
	  delta_x=x(1)-cov(1)
	  delta_y1=pv_y_hat-cov_y_hat-macro_ring_R
	  delta_y2=pv_y_hat-cov_y_hat+macro_ring_R
	  theta1=atan( delta_y1 / delta_x )
	  theta2=atan( delta_y2 / delta_x )
	
	  ! Find u for each vortex point
	  r1=sqrt(delta_x**2+delta_y1**2)
	  r2=sqrt(delta_x**2+delta_y2**2)
	  actual_line_count=3*line_count*(line_count-1)+1
	  if(r1.le.macro_ring_a) then
	    u_theta1=(actual_line_count*quant_circ*r1)/(2*pi*macro_ring_a**2)
      else
        u_theta1=(actual_line_count*quant_circ)/(2*pi*r1)
      end if
    	if(r2.le.macro_ring_a) then
	    u_theta2=-(actual_line_count*quant_circ*r2)/(2*pi*macro_ring_a**2)
      else
        u_theta2=(actual_line_count*quant_circ)/(2*pi*r2)
      end if
      u(1)=u_theta1*sin(theta1)+u_theta2*sin(theta2)
      u_y_hat=u_theta1*cos(theta1)+u_theta2*cos(theta2)
      u(2)=u_y_hat*cos(phi)
      u(3)=u_y_hat*sin(phi)
    
    end subroutine
    !************************************************************
end module
!>\page NF Normal fluid velocity field
!!Normal fluid velocity field is set in run.in throught the parameter normal_velocity\n
!!Options are:\n
!!- \p zero - no flow, friction only
!!- \p ABC - \f$\mathbf{u}=(\cos y+\sin z,\sin x+\cos z, \cos x+\sin y)\f$ \n
!! \image html NF_ABC_thumb.png
!!- \p xflow - \f$\mathbf{u}=(u_x,0,0)\f$ \n
!!- \p taylor-green - \f$\mathbf{u}=(\sin(x)\cos(y)\cos(z),-\cos(x)\sin(y)\cos(z),0)\f$\n
!! \image html NF_TG_thumb.png
!!- \p KS - multi-scale model of turbulence see KSmodel
!! \image html NF_KS_thumb.png
!!- \p shear - \f$\mathbf{u}=(0,0,u_0\exp(-z^2))\f$ \n
!! \image html NF_shear_thumb.png
!!- \p galloway-proctor - \f$\mathbf{u}=(\sin(y+\cos t)),-\cos(x+\sin t),\sin(x+\sin(t))+\cos(y+\cos(t)))\f$ \n
!! \image html NF_GP_thumb.png
!!- \p compressible - a compressible flow \f$\mathbf{u}=\nabla\phi\f$, where \f$\phi\f$ is a random scalar field
!! \image html NF_comp_thumb.png

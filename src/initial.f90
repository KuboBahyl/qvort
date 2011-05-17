!> Module which contains all the routines/call to routines which setup and
!!restart the code.
module initial
  use cdata
  use normal_fluid
  use initial_cond
  use forcing
  use periodic
  use smoothing
  use sph
  use inject
  contains
  !*************************************************************************
  !>Prints and sets up intial conditions - will give warnings/errors if there
  !>are any conflicting options set in run.in
  subroutine init_setup()
    use quasip
    use particles
    use mag !not strictly needed as mag used in timestep.mod used in quasip.mod 
    use sph
    implicit none
    logical :: restart
    write(*,'(a)') ' ---------------------VORTEX PARAMETERS------------------' 
    write(*,'(a,f9.7)') ' quantum of circulation is:', quant_circ 
    write(*,'(a,e9.3)') ' core size is:', corea 
    !check particle separation has been set
    if (delta<epsilon(0.)) call fatal_error('init.mod','delta must be set in run.in')
    !check that the particle count (pcount) has been set
    if (particles_only) then
      if (init_pcount>0) call fatal_error('init.mod','must have pcount=0 for particles_only')
    else
      if (init_pcount<5) then
        call fatal_error('init.mod','you must set enough intial particles')
      end if 
    end if
    !we must check the timestep is sufficient to resolve the motion
    !based on the smallest separation possible in the code
    if (delta_adapt) write(*,'(a)') ' mesh discretisation is adaptive'
    if (delta_adapt_print) write(*,'(a)') ' printing adaptive mesh information to file'
    write(*,'(a)') ' ---------------------TIME-STEP--------------------' 
    call timestep_check !initial.mod
    if (dt_adapt) then
      write(*,'(a)') ' using an adpative timestepping routine - in testing!'
    end if
    if (phonon_emission) then
      write(*,'(a)') ' ------------------PHONON EMISSION--------------------' 
      write(*,'(a,f6.2,a,f8.1)') ' simulating phonon emission, cutoff is ', 100*phonon_percent, '% of max:', 2/delta
    end if
    !loop injection
    call setup_vortex_injection
    !how is data being outputted (binary or formatted)
    write(*,'(a)') ' ---------------------DATA FORMAT--------------------' 
    if (binary_print) then
      write(*,*) 'binary data output, formatted data can be selected in run.in'
    else
      write(*,*) 'formatted data output selected in run.in'
    end if
    write(*,'(a,i3.2,a)') ' outputting filament information every ', shots, ' time-steps'
    !periodic bounday conditions?
    write(*,'(a)') ' ---------------------BOUNDARY CONDITIONS--------------------' 
    if (box_size>0.) then
      !what is the boundary
      select case(boundary)
        case('periodic')
          periodic_bc=.true.
          write(*,'(a,f8.3)') ' running with periodic boundaries, box size:', box_size
        case('openx')
          periodic_bc_notx=.true.
          write(*,'(a,f8.3)') ' running with periodic boundaries in y-z direction, box size:', box_size
          write(*,*) ' boundaries open in the x direction, loops that have left the box will be removed'
        case('mirror')
          mirror_bc=.true.
          call warning_message('init.mod','mirror b.c.s are still in testing and will probably fail at some point in the run!')
          select case(velocity)
            case('LIA','Tree')
              call fatal_error('init_setup','mirror bcs are not set up to work with the LIA/Tree veloctity')
          end select
          write(*,'(a,f8.3)') ' running with mirrored boundaries, box size:', box_size
          if (mirror_print) write(*,*) 'printing mirror filaments to file'
        case('open')
          write(*,*) 'running with open boundaries'
        case('open-remove')
          write(*,*) 'running with open boundaries - will remove loops which touch boundaries'
        case default
          call fatal_error('init_setup:', 'incorrect boundary parameter')
      end select
      !check if the box has been stretched in the x direction?
      select case(boundary)
        case('open-remove')
          write(*,'(a,f8.3,a)') 'x direction is a factor ', xdim_scaling_factor, ' longer'
        case default
          xdim_scaling_factor=1. !overwrite what is in run.in file - maybe print to say so?
      end select
    else
      call fatal_error('init_setup:', 'box size is less than zero')
    end if
    write(*,'(a)') ' --------------------NORMAL FLUID--------------------' 
    call setup_normal_fluid !normal_fluid.mod
    !sort out if there is a special dump time
    int_special_dump=int(special_dump/dt) !convert to integer
    write(*,'(a)') ' --------------------INITIAL CONDITIONS--------------------' 
    !check if we can restart the code
    inquire(file="./data/var.dat", exist=restart)
    if (restart) then
      call data_restore !init.mod
    else if (particles_only.eqv..false.) then
      pcount=init_pcount
      allocate(f(pcount)) !main vector allocated
      !choose the correct setup routine based on the value of initf in run.in
      select case(initf)
        case('single_loop')
          call setup_single_loop !initial_cond.mod
        case('single_line')
          call setup_single_line !initial_cond.mod
        case('ellipse')
          call setup_ellipse !initial_cond.mod
        case('random_loops')
          call setup_random_loops !initial_cond.mod
        case('crow')
          call setup_crow !initial_cond.mod
        case('leap-frog')
          call setup_leap_frog !initial_cond.mod
        case('linked_filaments')
          call setup_linked_filaments !initial_cond.mod
        case('colliding_loops')
          call setup_colliding_loops !initial_cond.mod
        case('kivotedes')
          call setup_kivotedes !initial_cond.mod
        case('cardoid')
          call setup_cardoid !initial_cond.mod
        case('hypotrochoid')
          call setup_hypotrochoid !initial_cond.mod
        case('wave_loop')
          call setup_wave_loop !initial_cond.mod
        case('linked_wave_loop')
          call setup_linked_wave_loop !initial_cond.mod
        case('wave_line')
          call setup_wave_line !initial_cond.mod
        case('lattice')
          call setup_lattice !initial_cond.mod
        case('tangle')
          call setup_tangle !initial_cond.mod
        case('criss-cross')
          call setup_criss_cross !initial_cond.mod
        !--------all SPH initial conditions below here--------
        case('SPH_loop')
          call setup_SPH_loop !initial_cond.mod
        case default
          call fatal_error('cdata.mod:init_setup', &
                         'invalid choice for initf parameter') !cdata.mod
      end select
    else
      !a dummy allocation of the main vector, probably not best practice!
      allocate(f(0))
      write(*,*) 'filament has not been set, running in particle only mode'
    end if
    !test if we have a non-zero mesh size
    write(*,'(a)') ' ------------------------MESH-----------------------' 
    if (mesh_size>0) then
      call setup_mesh !init.mod
    else
      write(*,*) 'velocity fields not being stored on a mesh - (no spectra etc.)'
    end if
    if (mesh_shots<shots) call warning_message('init.mod',&
                          'mesh shots < shots which will create output anomolies')
    !do we employ forcing on the boundary?
    write(*,'(a)') ' -----------------------FORCING-----------------------' 
    call setup_forcing !forcing,mod
    !are there quasi particles in the code?
    write(*,'(a)') ' ------------------------QUASI PARTICLES-----------------------' 
    if (quasi_pcount>0) then
      if (restart) then
        write(*,*) 'quasi particles have been restored from dump file, see above'
      else 
        call setup_quasip !quasip.mod
      end if
    else
      write(*,*) 'no quasi particles in the code'
    end if
    !are there particles in the code?
    write(*,'(a)') ' ------------------------PARTICLES-----------------------' 
    if (part_count>0) then
      if (restart) then
        write(*,*) 'particles have been restored from dump file, see above'
      else 
        call setup_particles !particles.mod
      end if
    else
      if (particles_only) then
        if (SPH_count==0) then 
          call fatal_error('init.mod','must have part_count>0 &
                            or SPH_count>0 for particles_only')
        end if
      end if
      write(*,*) 'no particles in the code'
    end if
    write(*,'(a)') ' ---------------------VELOCITY CALCULATION----------------------' 
    !is the tree code being used?
    if (tree_theta>0) then
      if (box_size>0.) then
        write(*,*) 'using tree algorithms for reconnection routine - scales like O(NlogN)'
      else
        call fatal_error('cdata.mod:init_setup','tree algorithms require a positive box size')
      end if
    else
      write(*,*) 'using brute force reconnection routine - scales like O(N^2)'
    end if
    !print information about the velocity field to screen
    select case(velocity)
      case('Off')
        select case(normal_velocity)
          case('zero')
            select case(force)
              case ('off')
                call warning_message('initial.mod',&
                'no superfluid velocity, no normal velocity, no forcing')
            end select
        end select
        write(*,*) 'No superfluid velocity: simulation of passive lines'
      case('LIA')
        write(*,*) 'using local induction approximation - scales like O(N)'
      case('BS')
        write(*,*) 'using full Biot-Savart integral - scales like O(N^2)'
      case('Rotate')
        write(*,*) 'by-passing all other velocity fields: prescribing differential rotation'
      case('SPH')
         if (SPH_count>0) then
            write(*,'(a)') ' using SPH particles for velocity field'
          else
            call fatal_error('initial.mod',' SPH_count must be >0 to use this condition')            
          end if
      case('Tree')
        if (tree_theta<epsilon(0.)) then 
          call fatal_error('init.mod:init_setup', & 
          'runnning with tree velocity but tree_theta is zero') !cdata.mod
        end if
        write(*,*) 'using tree approximation to Biot-Savart integral - scales like O(NlogN)'
        if (tree_theta>0.6) then
          call warning_message('init_setup','tree_theta>0.6, the vortices may be unstable')
        end if
     case default
       print*, 'correct value for velocity in run.in has not been set'
       print*, 'options are: LIA, BS, Tree,Rotate'
       call fatal_error('init.mod:init_setup', & 
        'correct value for "velocity" in run.in has not been set') !cdata.mod
    end select
    !any special diagnostic information?
    write(*,'(a)') ' ---------------------FURTHER DIAGNOSTICS----------------------' 
    if (simple_plots) write(*,*) 'producing simple plots on the fly'
    if (vapor_print) write(*,*) 'if we have mesh(s) then we will also print to file for vapor'
    if (curv_hist) write(*,*) 'printing histograms of curvature to file'
    if (topo_inf) write(*,*) 'printing topological information to file'
    if (energy_inf) then
      write(*,*) 'printing energy information to file'
      if (periodic_bc) call warning_message('init.mod','energy output is meaningless with periodic boundaries')
    end if
    if (vel_print) then
      write(*,'(a,i4.2,a)') ' printing full velocity information every: ', mesh_shots, ' timesteps'
      select case(normal_velocity)
        case('zero')
          if (vel_print_extra) call warning_message('init.mod','set to print extra velocity information with no normal fluid')
        case default
          if (vel_print_extra) write(*,*) 'printing extra velocity information'
      end select
    end if
    !final boundary conditions sanity check
    if (periodic_bc.and.mirror_bc) call fatal_error('init.mod','both periodic and mirror bcs are set')
    if (one_dim>0) write(*,'(a,i5.3)') ' printing 1D velocity info to file, mesh size: ', one_dim
    if (two_dim>0) write(*,'(a,i5.3)') ' printing 2D velocity info to file, mesh size: ', two_dim
    if (recon_info) write(*,*) 'printing extra reconnection information to file'
    if (switch_off_recon) call warning_message('init.mod','reconnections switched off: I HOPE YOU KNOW WHAT YOUR DOING!')
    if (boxed_vorticity) then
      write(*,'(a,i5.3,a)') 'calculating boxed vorticity every ',mesh_shots, ' timesteps'
      write(*,'(a,i5.3)') 'size of mesh: ',boxed_vorticity_size
      write(*,'(a)') 'I recommend that you fine tune the mesh size using the matlab routine: vorticity_field.m'
    end if
    !----------------------gaussian smoothing of field------------------------------
    if (sm_size>0) call setup_smoothing_mesh !smoothing.mod
    !----------------------------magnetic field-------------------------------------
    if (restart) then
      if (magnetic) write(*,*) 'restored magnetic field'
    else
      if (magnetic) call setup_mag !mag.mod
    end if
    !------------------------------SPH----------------------------------
    if (SPH_count>0) then
      call setup_SPH !sph.mod
    else
      !must check for printing to screen
      if (particles_only) then
        if (part_count==0) then 
          call fatal_error('init.mod','must have part_count>0 &
                            or SPH_count>0 for particles_only')
        end if
      end if
    end if
  end subroutine
  !**********************************************************************
  !>restart the code code periodically writes all the main variables to a file
  !>./data/dump.dat, if this is detected at startup then the code will restart
  !>from that data file
  subroutine data_restore
    !restart the code
    use stiff_solver
    implicit none
    integer :: dummy_itime 
    open(unit=63,file="./data/var.dat",FORM='unformatted')
      read(63) pcount
      read(63) recon_count
      read(63) dummy_itime
      read(63) t
      allocate(f(pcount))
      read(63) f
      write(*,*) 'restored vortex filament'
      read(63) quasi_pcount
      if (quasi_pcount>0) then
        allocate(g(quasi_pcount))
        read(63) g
        write(*,'(a,i4.1,a)') ' restored ', quasi_pcount,' quasi particles'
        !finally intialise the backwards difference coefficients array
        call set_BDF_coeff !stiff_solver.mod
      end if
      read(63) part_count
      if (part_count>0) then
        allocate(p(part_count))
        read(63) p
        write(*,'(a,i4.1,a)') ' restored ', part_count,' particles'
      end if
    close(63)
    nstart=dummy_itime+1
    write(*,*) 'data read in from dump file at t=', t
    if (quasi_pcount>0) then
      write(*,*)'note that the quasi particles will not be restored'
    end if
  end subroutine
  !****************************************************************
  !> setup the mesh if set by mesh_size being non-zero in run.in
  subroutine setup_mesh
    implicit none
    integer :: i,j,k
    real :: x,y,z
    if (mod(mesh_size,2)/=0) then
      call fatal_error('init.mod:setup_mesh', &
      'mesh size must be a multiple of 2')
    end if
    if (mesh_size<16) call warning_message('setup_mesh','warning mesh size is small')
    mesh_delta=real(box_size)/mesh_size
    write(*,'(a,i3.2,a,f7.6)') ' creating an n^3 mesh, n=', mesh_size, ' resolution=', mesh_delta
    write(*,'(a,i5.2,a)') ' mesh information will be printed every ', mesh_shots, ' time-steps'
    allocate(mesh(mesh_size,mesh_size,mesh_size))
    do k=1, mesh_size
      do j=1, mesh_size
        do i=1, mesh_size
          x=mesh_delta*real(2*i-1)/2.-(box_size/2.)
          y=mesh_delta*real(2*j-1)/2.-(box_size/2.)
          z=mesh_delta*real(2*k-1)/2.-(box_size/2.)
          mesh(k,j,i)%x(1)=x ; mesh(k,j,i)%x(2)=y ; mesh(k,j,i)%x(3)=z
          !clear the velocity slots - for safety
          mesh(k,j,i)%u_sup=0. ; mesh(k,j,i)%u_norm=0.
        end do
      end do
    end do
  end subroutine
  !******************************************************************
  !> check the timestep is OK if we have a vortex filament only
  subroutine timestep_check
    implicit none
    real :: delta_min, dt_max
    select case(velocity)
      case('Off','Rotate','SPH')
        write(*,'(a)') ' dt not checked as not solving for a vortex'
        return
    end select
    delta_min=delta/2.
    dt_max=((delta_min)**2)/(quant_circ*log(delta_min*1E8/pi))
    if (dt<dt_max) then
      write(*,'(a,e10.4)') ' dt is below maximum possible dt:', dt_max
    else
      write(*,'(a,e10.4)') ' warning set dt below ', dt_max
      call fatal_error('initial.mod:timestep_check','dt is too large')
    end if
  end subroutine
end module
!********************************************************************

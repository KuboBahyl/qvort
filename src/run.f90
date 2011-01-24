program run
  !THE MAIN PROGRAM
  use cdata
  use initial
  use output
  use periodic
  use timestep
  use quasip
  use line
  use diagnostic
  use quasip
  use tree
  use mirror
  implicit none
  integer :: i
  logical :: can_stop=.false.
  call init_random_seed !cdata.mod
  !read in parameters
  call read_run_file !cdata.mod
  !initial conditions - checks for restart?
  call init_setup !initial.mod
  !print dimensions info for matlab plotting
  call print_dims !output.mod
  !begin time loop
  write(*,*) 'setup complete: beginning time loop'
  do itime=nstart, nsteps
    call ghostp !periodic.mod
    !---------------------build tree routines----------------------
    if (tree_theta>0) then
      call construct_tree !tree.mod
    end if
    !---------------------create mirror array----------------------
    if (mirror_bc) call mirror_init !mirror.mod
    !---------------------velocity operations----------------------
    call pmotion !timestep.mod
    !print*, 'here1'
    if (mod(itime,mesh_shots)==0) then
      call mesh_velocity !timestep.mod
    end if
    !print*, 'here2'
    !---------------------diagnostic info--------------------------
    if (mod(itime, shots)==0) then
      call velocity_info !diagnostics.mod
      call energy_info !diagnostics.mod
      call curv_info !diagnostics.mod
    end if
    !print*, 'here3'
    !---------------------line operations--------------------------
    call premove !line.mod 
    call pinsert !line.mod
    if (mod(itime, recon_shots)==0) then
      if (tree_theta>0) then
        !we may need to empty the tree and then redraw it at this point
        call pclose_tree !tree.mod
      else
        call pclose !line.mod
      end if
      call precon !line.mod
    end if
    !print*, 'here4'
    if(periodic_bc) call enforce_periodic !periodic.mod
    !---------------once all algorithms have been run--------------
    t=t+dt  !increment the time
    !--------------now do all data output--------------------------
    if (mod(itime, shots)==0) then
      !print to file
      call printf(itime/shots) !output.mod
      !store data to a binary file for reload
      call data_dump !output.mod
      call print_info !output.mod
      if (mod(itime, mesh_shots)==0) then
        !print the mesh to a binary file
        call print_mesh(itime/mesh_shots) !output.mod
        !can also print full velocity field for statistics 
        call print_velocity(itime/mesh_shots) !output.mod
        call one_dim_vel(itime/mesh_shots) !diagnostics.mod
        call two_dim_vel(itime/mesh_shots) !diagnostics.mod
      end if
    end if
    !print*, 'here5'
    !---do we have particles in the code - if so evolve them
    if (quasi_pcount>0) call quasip_evolution !quasip.mod
    !-------------------remove the tree----------------------------
    if (tree_theta>0) then
      call empty_tree(vtree) !empty the tree to avoid a memory leak
      deallocate(vtree%parray) ; deallocate(vtree)
      nullify(vtree) !just in case!
    end if
    !---------------------close mirror array-----------------------
    if (mirror_bc) call mirror_close !mirror.mod
    !---------------------special data dump------------------------
    if ((itime/=0).and.(itime==int_special_dump)) call sdata_dump
    !---------------------can we exit early------------------------
    if (mod(itime,shots)==0) then
      inquire(file='./STOP', exist=can_stop)
      if (can_stop) then
        write(*,*) 'Encountered stop file, ending simulation'
        stop
      end if
    end if
    !--------------------------------------------------------------
    t=t+dt !finish by incrementing time 
  end do
  !deallocate(f,mesh) !tidy up
end program

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
  implicit none
  integer :: i
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
    !---------------------velocity operations----------------------
    call pmotion !timestep.mod
    if (mod(itime,shots*10)==0) then
      call mesh_velocity !timestep.mod
    end if
    !---------------------diagnostic info--------------------------
    if (mod(itime, shots)==0) then
      call velocity_info !diagnostics.mod
    end if
    !---------------------line operations--------------------------
    call pinsert !line.mod
    if (mod(itime, recon_shots)==0) then
      call pclose !line.mod
      call precon !line.mod
      call premove !line.mod
    end if
    if(periodic_bc) call enforce_periodic !periodic.mod
    !--------------now do all data output--------------------------
    if (mod(itime, shots)==0) then
      !print to file
      call printf(itime/shots) !output.mod
      !store data to a binary file for reload
      call data_dump !output.mod
      call print_info !output.mod
      !print the mesh to a binary file
      if (mod(itime, 10*shots)==0) then
        call print_mesh(itime/(10*shots)) !output.mod
      end if
    end if
    !----build the tree--------------------------------------------
    !all this will be in timestep once it is finished
    if (tree_theta>0) then
      call construct_tree !tree.mod
      !find the closest particles
      do i=1, pcount
       f(i)%closestd=10. !arbitaritly high
      end do
      !remove the tree
      call empty_tree(vtree) !empty the tree to avoid a memory leak
      deallocate(vtree%parray) ; deallocate(vtree)
      nullify(vtree) !just in case!
    end if
    !---do we have particles in the code - if so evolve them
    if (quasi_pcount>0) call quasip_evolution !quasip.mod
    !special data dump
    if ((itime/=0).and.(itime==int_special_dump)) call sdata_dump
    !--------------------------------------------------------------
  end do
  deallocate(f,mesh) !tidy up
!still to do:-
!tree
end program

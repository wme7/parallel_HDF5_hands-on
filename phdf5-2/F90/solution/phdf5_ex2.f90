
! ###################################################################
! #                       HDF5 hands on                             #
! #  Created : April 2011                                           # 
! #                                                                 #
! #  Author:                                                        #
! #     Matthieu Haefele                                            #
! #     matthieu.haefele@ipp.mpg.de                                 #
! #     High Level Support Team (HLST)                              #
! #     Max-Planck Institut fuer Plasmaphysik                       #
! #                                                                 #
! ###################################################################

PROGRAM PHDF5_EX
     USE HDF5
     use mpi

     IMPLICIT NONE

     CHARACTER(LEN=10), PARAMETER :: filename = "example.h5" ! File name
     CHARACTER(LEN=8), PARAMETER :: dsetname = "IntArray"     ! Dataset name
     CHARACTER(LEN=15) :: obj_name 
     INTEGER, PARAMETER     ::   rank = 2                        
     INTEGER, PARAMETER     ::   NX = 16                        
     INTEGER, PARAMETER     ::   NY = 32                        

     INTEGER(HID_T) :: file, dataset, dataspace, filespace, memspace
     INTEGER(HSIZE_T), DIMENSION(2) :: dims, start, el_count
     INTEGER     ::   status
     INTEGER, DIMENSION(:,:), allocatable :: dat
     INTEGER     :: i,j,var_nx, var_ny, size_x, size_y, offset_x, offset_y 
     integer :: mpi_id, size, ierr
    
     CALL MPI_INIT( ierr )
     CALL MPI_COMM_RANK( MPI_COMM_WORLD, mpi_id, ierr )
     CALL MPI_COMM_SIZE( MPI_COMM_WORLD, size, ierr )

     if(size .ne. 1 .and. size .ne. 4 .and. size .ne. 16) then
       if(mpi_id==0) then
         print*, "Error: Authorized number of process is 1, 4 or 16, exiting..."
       end if 
       call MPI_Abort(MPI_COMM_WORLD, 1, ierr)
     end if

     var_nx = NX
     var_ny = NY
     call init(var_nx, var_ny, mpi_id, size, size_x, size_y, offset_x, offset_y, dat) 
        
     !
     ! Initialize FORTRAN predefined datatypes.
     !
     CALL h5open_f(status)

     if(mpi_id == 0) then
       !HDF5 file creation
       CALL h5fcreate_f(filename, H5F_ACC_TRUNC_F, file, status)

       !Dataspace creation
       dims(1) = NX 
       dims(2) = NY
       CALL h5screate_simple_f(rank, dims, dataspace, status)

       !Dataset creation 
       CALL h5dcreate_f(file, dsetname, H5T_NATIVE_INTEGER, dataspace, &
       dataset, status)

       !Actual data IO
       el_count(1) = size_x
       el_count(2) = size_y
       start(1) = offset_x
       start(2) = offset_y
       CALL h5screate_simple_f(rank, el_count, memspace, status)
       CALL h5screate_simple_f(rank, dims, filespace, status)
       CALL H5sselect_hyperslab_f(filespace, H5S_SELECT_SET_F, start, el_count, status)
       CALL h5dwrite_f(dataset, H5T_NATIVE_INTEGER, dat, el_count, status, &
       mem_space_id=memspace, file_space_id=filespace)

       !Closing all opened HDF5 objects
       CALL h5dclose_f(dataset, status)
       CALL h5sclose_f(dataspace, status)
       CALL h5sclose_f(filespace, status)
       CALL h5sclose_f(memspace, status)
       CALL h5fclose_f(file, status)
     end if

     call MPI_Barrier(MPI_COMM_WORLD, ierr)

     do i=1, size-1
       if(i==mpi_id) then
         !HDF5 file opening
         CALL h5fopen_f(filename, H5F_ACC_RDWR_F, file, status)

         !Dataset opening
         CALL h5dopen_f(file, dsetname, dataset, status)

         !Actual data IO
         dims(1) = NX 
         dims(2) = NY
         el_count(1) = size_x
         el_count(2) = size_y
         start(1) = offset_x
         start(2) = offset_y
         CALL h5screate_simple_f(rank, el_count, memspace, status)
         CALL h5screate_simple_f(rank, dims, filespace, status)
         CALL H5sselect_hyperslab_f(filespace, H5S_SELECT_SET_F, start, el_count, status)
         CALL h5dwrite_f(dataset, H5T_NATIVE_INTEGER, dat, el_count, status, &
         mem_space_id=memspace, file_space_id=filespace)

         !Closing all opened HDF5 objects
         CALL h5dclose_f(dataset, status)
         CALL h5sclose_f(filespace, status)
         CALL h5sclose_f(memspace, status)
         CALL h5fclose_f(file, status)
       end if
       call MPI_Barrier(MPI_COMM_WORLD, ierr)
     end do

     CALL h5close_f(status)

     CALL MPI_FINALIZE(ierr)


     contains
subroutine init(NX, NY, mpi_id, size, size_x, size_y, offset_x, offset_y , dat)
  integer, intent(in) :: NX, NY, mpi_id, size
  integer, intent(out) :: size_x, size_y, offset_x, offset_y 
  integer :: i,j
  integer, dimension(:,:), allocatable :: dat
  integer :: nb_proc_per_dim
  nb_proc_per_dim = int(sqrt(real(size)))
  size_x = NX/nb_proc_per_dim
  size_y = NY/nb_proc_per_dim
  offset_x = mod(mpi_id,nb_proc_per_dim) * size_x
  offset_y = int(mpi_id/nb_proc_per_dim) * size_y

  allocate(dat(size_x,size_y))

  do j=1, size_y
    do i=1, size_x
      dat(i,j) = i+offset_x-1 + (j+offset_y-1)*NX;
    end do
  end do

end subroutine init

END PROGRAM PHDF5_EX
     

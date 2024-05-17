! Example program to load a raster file with fortrangis     

program loadraster
    ! Default Fortran 2018 include
    use, intrinsic :: iso_fortran_env, only: int32, real32
    ! Include GDAL FortranGIS bindings
    use gdal
    ! Include C Fortran GIS bindings
    use fortranc
    ! Default to none
    implicit none
    ! Declare argc, argv
    integer :: arg_len, stat
    character(len=:), allocatable :: arg_str
    ! Declare iterator
    integer(int32) :: i, j
    ! Declare allocatable array for pixel storage
    real(kind=c_double), allocatable, target, dimension(:,:) :: array
    ! Declare pointer to array
    type(c_ptr) :: a_ptr
    ! Declare placeholder for length of array
    integer(int32) :: len_array
    ! Declare nrows and ncols placeholders from the raster image
    integer(kind=c_int) :: band, nbands, nrows, ncols, offrow, offcol
    ! Garbage collection
    integer(kind=c_int) :: err ! CPLErr
    
    ! Create a GDAL dataset handle
    type(GDALDataSetH) :: ds, dsOut
    ! Create a GDAL band handle
    type(GDALRasterBandH) :: bandH, OutbandH
    ! Create a GDAL driver handle
    type(GDALDriverH) :: hDriver
    ! Allocate metadata pointer (libfortrangis?)
    type(c_ptr_ptr) :: meta
    ! Load GDAL constants and drivers definitions
    call gdalallregister()

    ! Get length of command-line argument
    call get_command_argument(1, length=arg_len)
    
    ! Allocate character string to hold argument
    allocate(character(len=arg_len) :: arg_str)
    
    ! Get command-line argument (number 1 is input file)
    call get_command_argument(1, arg_str)

    ! Open raster file from argument
    ds = gdalopen(TRIM(arg_str)//CHAR(0), GA_ReadOnly)

    ! Get the raster input file driver info
    hDriver = GDALGetDatasetDriver(ds)
    
    ! Get command-line argument (number 2 is output file) 
    call get_command_argument(2, arg_str)

    ! Create an output copy
    dsOut = GDALCreateCopy(hDriver, TRIM(arg_str)//CHAR(0), ds, 0, c_null_ptr, c_null_ptr, c_null_ptr)

    ! Extract metadata information
    meta = c_ptr_ptr_new(GDALGetMetadata(gdalmajorobjecth_new(ds), CHAR(0)))

    ! Print the metadata content to stdout
    do i = 1, c_ptr_ptr_getsize(meta)
        write(*,'(I4,A)') i,TRIM(strtofchar(c_ptr_ptr_getptr(meta, i), 100))
    end do
   
    ! Discover the rows and columns of the raster image
    nrows = GDALGetRasterYSize(ds) 
    ncols = GDALGetRasterXSize(ds) 
    
    ! Allocate band array
    allocate(array(ncols,nrows))

    ! Get the c pointer to the array
    a_ptr = c_loc(array)

    ! Discover the number of bands
    nbands =  GDALGetRasterCount(ds)
    
    ! Iterate on all bands
    do band=1, nbands
        ! load iteratively the band handle of the input dataset ds
        bandH = GDALGetRasterBand(ds, band)

        ! load iteratively the band hadle of the output dataset dsOut
        OutBandH = GDALGetRasterBand(dsOut, band)

        ! Load pixels into 1D array
        ! err = gdalrasterio(hband,erwflag,ndsxoff,ndsyoff,ndsxsize,ndsysize,C_LOC(pbuffer(1,1)),ndsxsize,ndsysize,GDT_Byte,0,0)
        err = GDALRasterIO(bandH, GF_Read, offcol, offrow, ncols, nrows, a_ptr, SIZE(array,1), SIZE(array,2), GDT_Float64, 0, 0)

        ! Do concurrent construct
        do concurrent (i=1:ncols)
            do concurrent (j=1:nrows)
                array(i,j) = array(i,j) + 1
            end do
        end do

        ! Write output array to the band handle in the output file
        err = GDALRasterIO(OutBandH, GF_Write, offcol, offrow, ncols, nrows, a_ptr, SIZE(array,1), SIZE(array,2), GDT_Float64, 0, 0)
    end do
    
    ! Deallocate
    deallocate(array)

    ! Write output to new raster on disk
    call GDALClose(ds)
    call GDALClose(dsOut)

end program loadraster


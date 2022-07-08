C lf95 nos_ofs_create_tidalforcing_ROMS.f write_netCDF_tidalforcing_ROMS.f equarg.f
C trisubs.f tripack.f utility.f -I/usr/local/include -L/usr/local/lib -lnetcdf -o
C nos_ofs_create_tidalforcing_ROMS.x
C----------------------------------------------------------------------------------
C
C Program Name:  nos_ofs_create_tidalforcing_ROMS.f
C
C Directory:  /gpfs/d/marine/save/wx21az/COMF_NCEP/sorc/nos_reformatfor.fd/oceans
C
C Purpose:    This Program is used to generated tidal forcing file for ROMS from  
C             ADCIRC EC2001 database generated by Jesse Feyen in CSDL.
C             The data (Harmonic Constants of EL, UBAR, and VBAR) on ADCIRC grid are
C             horizontally interpolated onto ROMS water cells using remesh routine. 
C             
C             node factor and equilibrium arguments for the middle of each year 
C             (day 183 or 184) are used in the same calender year regardless of 
C             the length of time series. This is consistent with CO-OPS tidal prediction programs
C             The final harmonics can be corrected with user provided data.
C
C Current contact:   Aijun Zhang
C         Org:  NOS/CO-OPS/OD   Phone:  301-713-2890 ext. 127 
C                    aijun.zhang@Noaa.gov 
C Attributes:
C  Language:  Fortran
C  Computer:  DEW/MIST at NCEP  
C
C  Compile command:  make -f Make_nos_ofs_create_tidalforcing_ROMS
C
C Subprograms called:   remesh, regrid, write_netCDF_tidalforcing_ROMS, equarg, utility
C
C Input Data files:
C   /marine/save/wx21az/NOS_OFS/fix/EC2001_NOS_euv.nc
C
C Usage:   nos_ofs_create_tidalforcing_ROMS < Fortran.ctl 
C
C
C Input Parameters:
C           OFS         : name of Operational Forecast System, e.g. CBOFS, TBOFS
C        Ocean_MODEL    : Name of numerical ocean model used in OFS, e.g. ROMS, FVCOM
C        TIME_START     : Start time 
C        FORHRS         : Length of forecast time in hours
C        IGRD           : indicator of horizontal interpolation method
C                        =1:  remesh using triangulation techniques
C        GRIDFILE       : Grid file name of the OFS			   
C        HC_FILE        : ADCIRC EC2001 harmonic constant file name			   
C        OUTPUTFILE     : Output file name  
C        BASE_DATE      : base date of OFS model simulation time.
C        MINLON         :longitude of lower left/southwest corner to cover the OFS domain
C        MINLAT         :latitude of lower left /southwest corner to cover the OFS domain
C        MINLON         :longitude of upper right/northeast corner to cover the OFS domain
C        MINLAT         :latitude of  upper right/northeast corner to cover the OFS domain
C    EL_HC_CORRECTION   : > 0 correction elevation harmonics with user provided data 
C FILE_EL_HC_CORRECTION : file name contains harmonics for correction.
C
C Output files: 
C    A netCDF tidal forcing file for ROMS contains the required variables. 
C----------------------------------------------------------------------------------
      PARAMETER(PI=3.1415926,R2D=180.0/PI,D2R=PI/180.0)
      include 'netcdf.inc'
      character*120 OFS,DBASE*10,OCEAN_MODEL*10,DBASE_WL*20
      character*120 BUFFER,HC_FILE,FOUT,GRIDFILE,netcdf_file
      character*120 EL_HC_CORRECTION,START_TIME
      real*8 jdays,jdaye,jbase_date,JULIAN,yearb,monthb,dayb,hourb
      real*8 jday,jday0,js_etss,je_etss
      real minlon,minlat,maxlat,maxlon
      LOGICAL FEXIST
      INTEGER BASE_DATE(4)
      INTEGER DAYS_PER_MONTH(12)
      DATA (DAYS_PER_MONTH(i),I=1,12) /
     &31,28,31,30,31,30,31,31,30,31,30,31/ 
cc allocatable arrays for ROMS model
      real*4, allocatable :: lonm  (:,:)
      real*4, allocatable :: latm  (:,:)
      real*4, allocatable :: angm  (:,:)
      real*4, allocatable :: maskm  (:,:)
      real*4, allocatable :: hm  (:,:)
      real*4, allocatable :: Iout(:,:)
      real*4, allocatable :: Jout(:,:)
      integer, allocatable :: IWATER(:)
      integer, allocatable :: JWATER(:)
      real*4, allocatable :: Eampm  (:,:,:)
      real*4, allocatable :: Epham  (:,:,:)
      real*4, allocatable :: Uampm  (:,:,:)
      real*4, allocatable :: Upham  (:,:,:)
      real*4, allocatable :: Vampm  (:,:,:)
      real*4, allocatable :: Vpham  (:,:,:)
      
      real*4, allocatable :: semam  (:,:,:)
      real*4, allocatable :: semim  (:,:,:)
      real*4, allocatable :: Aincm  (:,:,:)
      real*4, allocatable :: Phim  (:,:,:)

      real*4, allocatable :: tide_period(:)
      character*10,allocatable :: tidenames(:)
      integer dimids(5),COUNT(4)
      INTEGER :: status      ! Return status
      real*4, allocatable :: oned1(:)
      real*4, allocatable :: oned2(:)
      real*4, allocatable :: oned3(:)
      real*4, allocatable :: oned4(:)
      real*4, allocatable :: twod1(:,:)
      real*4, allocatable :: tmp2d  (:,:)
      real*4, allocatable :: tmp3d  (:,:,:)
      real*4, allocatable :: tmp4d  (:,:,:,:)
      integer, allocatable :: Ioned1(:)
      integer, allocatable :: Ioned2(:)
 
CCCCCCCCCCCCCC  used by equarg.f
      real*8 spd(180),fff(180),vau(180),VPU(180),XODE(180),a(180)
      character*10 labl(180),ALIST(37)
      DATA (ALIST(I),I=1,37) /'M(2)      ','S(2)      ','N(2)      ',
     1                        'K(1)      ','M(4)      ','O(1)      ',
     2                        'M(6)      ','MK(3)     ','S(4)      ',
     3                        'MN(4)     ','NU(2)     ','S(6)      ',
     4                        'MU(2)     ','2N(2)     ','OO(1)     ',
     5                        'LAMBDA(2) ','S(1)      ','M(1)      ',
     6                        'J(1)      ','MM        ','SSA       ',
     7                        'SA        ','MSF       ','MF        ',
     8                        'RHO(1)    ','Q(1)      ','T(2)      ',
     9                        'R(2)      ','2Q(1)     ','P(1)      ',
     1                        '2SM(2)    ','M(3)      ','L(2)      ',
     2                        '2MK(3)   ','K(2)      ','M(8)      ',
     3                        'MS(4)     '/
      DATA (A(I), I=1,37)/ 28.9841042d0,  30.0000000d0,  28.4397295d0,
     115.0410686d0,57.9682084d0,13.9430356d0,86.9523127d0,44.0251729d0,
     260.0000000d0,57.4238337d0,28.5125831d0,90.0000000d0,27.9682084d0,
     327.8953548d0,16.1391017d0,29.4556253d0,15.0000000d0,14.4966939d0,
     415.5854433d0, 0.5443747d0, 0.0821373d0, 0.0410686d0, 1.0158958d0,
     5 1.0980331d0,13.4715145d0,13.3986609d0,29.9589333d0,30.0410667d0,
     612.8542862d0,14.9589314d0,31.0158958d0,43.4761563d0,29.5284789d0,
     742.9271398d0,30.0821373d0, 115.9364169d0,58.9841042d0/

CCCCCCCCCCCCCC
      call macheps(eps)
      
      read(5,'(a120)')OFS
      read(5,'(a10)')OCEAN_MODEL
      
      read(5,'(a120)')BUFFER
      START_TIME=trim(adjustL(BUFFER))
      read(START_TIME,'(I4,4I2)')IYR,IMM,IDD,IHH,IMN
!      read(5,*)IYR,IMM,IDD,IHH
      read(5,'(a120)')BUFFER
      do i=1,len_trim(BUFFER)
          if(BUFFER(i:I) .eq. "'" .or. BUFFER(i:I) .eq. '"')then
	    BUFFER(i:I)=' '
	  endif    
      enddo
      GRIDFILE=trim(adjustL(BUFFER))
      print *,'gridfile=',trim(gridfile)
      read(5,'(a120)')BUFFER
      do i=1,len_trim(BUFFER)
         if(BUFFER(i:I) .eq. "'" .or. BUFFER(i:I) .eq. '"')then
	    BUFFER(i:I)=' '
	 endif    
      enddo
      HC_FILE=trim(adjustL(BUFFER))
      read(5,'(a120)')BUFFER
      do i=1,len_trim(BUFFER)
        if(BUFFER(i:I) .eq. "'" .or. BUFFER(i:I) .eq. '"')then
	    BUFFER(i:I)=' '
	 endif    
      enddo
      FOUT=trim(adjustL(BUFFER))
      read(5,'(a120)')BUFFER
      do i=1,len_trim(BUFFER)
         if(BUFFER(i:I) .eq. "'" .or. BUFFER(i:I) .eq. '"')then
            BUFFER(i:I)=' '
	 endif    
      enddo
      BUFFER=trim(adjustL(BUFFER))
      read(BUFFER,'(I4,3i2)')base_date
CC  WRITE OUT INPUT PARAMETERS
      WRITE(*,*)'OFS= ',TRIM(OFS)
      WRITE(*,*)'OCEAN_MODEL= ',TRIM(OCEAN_MODEL)
      WRITE(*,*)'START TIME= ',IYR,IMM,IDD,IHH
      WRITE(*,*)'MODEL GRID FILE=',TRIM(GRIDFILE)
      WRITE(*,*)'HARMONIC CONSTANT FILE IS ',trim(HC_FILE)
      WRITE(*,*)'OUTPUT TIDAL FORCING FILE IS ',trim(FOUT) 
      WRITE(*,*)'base date = ',base_date
CCCCCCCCCCCCCCC      
      yearb=base_date(1)
      monthb=base_date(2)
      dayb=base_date(3)
      hourb=base_date(4)
      jbase_date=JULIAN(yearb,monthb,dayb,hourb)
C--------------------------------------------------------------------------------------------- 
C     compute node factor and equilibrium arguments of each year
C     determine all the predictions constituents by speed
      do i=1,37
         call name (a(i),labl(i),isub,inum,1)
!	 print *,'tidename=',I,labl(i),a(i)
      enddo
C node factor and equilibrium arguments for the middle of each year (day 183 or 184) are used in 
C the same calender year regardless of the length of time series. This is consistent with CO-OPS
C tidal prediction programs
C 
      call equarg (37,IYR,1,1,365,labl(1),fff(1),vau(1))
      WRITE(*,*)'node factor and equilibrium arguments for year: ',IYR
      do j=1,37
        VPU(J)=VAU(J)
        XODE(J)=FFF(J)
        WRITE(6,'(I2,2x,A10,1x,F12.7,2X,F6.1,2X,F9.4)')
     1  J, ALIST(J),A(J),VPU(J),XODE(J)
      end do
      yearb=IYR
      monthb=IMM
      dayb=IDD
      hourb=0   
      jday=JULIAN(yearb,monthb,dayb,hourb)
      TIDE_START=jday-jbase_date
C--------------------------------------------------------------------------------------------- 
CC read in ROMS model grid information
      IF (trim(OCEAN_MODEL) .EQ. "ROMS")THEN
        WRITE(*,*)'Reading ROMS grid file ...',trim(GRIDFILE)
        STATUS = NF_OPEN(trim(GRIDFILE),NF_NOWRITE, NCID_GRD)
        IF(STATUS .NE. NF_NOERR)then
	   print *,'error message= ',status
	   stop 'open grid file failed'
        ENDIF  
        STATUS = NF_INQ(NCID_GRD,NDIMS,NVARS,NGATTS,IDUNLIMDIM)
        DO I=1,NDIMS
          STATUS = NF_INQ_DIM(NCID_GRD,i,BUFFER,ILATID)
          STATUS = NF_INQ_DIMLEN(NCID_GRD,i,latid)
          if(trim(BUFFER) .eq. 'eta_rho')JROMS=latid
          if(trim(BUFFER) .eq. 'xi_rho')IROMS=latid
        ENDDO
        NNMODEL=IROMS*JROMS
        ALLOCATE(lonm(IROMS,JROMS) )
        ALLOCATE(latm(IROMS,JROMS) )
        ALLOCATE(angm(IROMS,JROMS) )
        ALLOCATE(maskm(IROMS,JROMS) )
        ALLOCATE(hm(IROMS,JROMS) )
        STATUS = NF_INQ_VARID(NCID_GRD,'lon_rho',IDVAR)
        STATUS = NF_GET_VAR_REAL(NCID_GRD,IDVAR,lonm)
        STATUS = NF_INQ_VARID(NCID_GRD,'lat_rho',IDVAR)
        STATUS = NF_GET_VAR_REAL(NCID_GRD,IDVAR,latm)
        STATUS = NF_INQ_VARID(NCID_GRD,'angle',IDVAR)
        STATUS = NF_GET_VAR_REAL(NCID_GRD,IDVAR,angm)
        STATUS = NF_INQ_VARID(NCID_GRD,'mask_rho',IDVAR)
        STATUS = NF_GET_VAR_REAL(NCID_GRD,IDVAR,maskm)
        STATUS = NF_INQ_VARID(NCID_GRD,'h',IDVAR)
        STATUS = NF_GET_VAR_REAL(NCID_GRD,IDVAR,hm)
        STATUS=NF_CLOSE(NCID_GRD)
      ENDIF
CC  search for water cells in model grid
      ICOUNT=0
      DO J=1,JROMS
      DO I=1,IROMS
        IF(maskm(I,J) .GT. 0.5)ICOUNT=ICOUNT+1
      ENDDO
      ENDDO
      NWATER=ICOUNT
      ALLOCATE(IWATER(NWATER) )
      ALLOCATE(JWATER(NWATER) )
      ICOUNT=0
      DO J=1,JROMS
      DO I=1,IROMS
        IF(maskm(I,J) .GT. 0.5)then
	  ICOUNT=ICOUNT+1
	  IWATER(ICOUNT)=I
	  JWATER(ICOUNT)=J
	  write(34,11)ICOUNT,I,J,lonm(i,j),latm(i,j),maskm(i,j)
	ENDIF  
      ENDDO
      ENDDO
11    FORMAT(I8,2I5,2F10.4,F4.1)     
      NWATER=ICOUNT
      write(*,*)'number of water cells in the model domain =',NWATER        
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!zaj
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
CC read in Harmonic Constiutents on ROMS grid from HC_FILE       
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
      STATUS = NF_OPEN(trim(HC_FILE),NF_NOWRITE, NCID)
      IF(STATUS .NE. NF_NOERR)then
	   print *,'error message= ',status
	   stop 'open HC_FILE file failed'
      ENDIF  
      STATUS = NF_INQ(NCID,NDIMS,NVARS,NGATTS,IDUNLIMDIM)
      DO I=1,NDIMS
          STATUS = NF_INQ_DIM(NCID,i,BUFFER,ILATID)
          STATUS = NF_INQ_DIMLEN(NCID,i,latid)
          if(trim(BUFFER) .eq. 'eta_rho')JDUMMY=latid
          if(trim(BUFFER) .eq. 'xi_rho')IDUMMY=latid
          if(trim(BUFFER) .eq. 'tide_period')NC=latid
          if(trim(BUFFER) .eq. 'charlength')NCHAR=latid
      ENDDO
      IF(JDUMMY .NE. JROMS)THEN
	  WRITE(*,*)'eta dimension does not match'
	  STOP
      ENDIF  
      IF(IDUMMY .NE. IROMS)THEN
	  WRITE(*,*)'xi dimension does not match'
	  STOP
      ENDIF 
      ALLOCATE(Eampm(IROMS,JROMS,NC) )
      ALLOCATE(Epham(IROMS,JROMS,NC) )
      ALLOCATE(Uampm(IROMS,JROMS,NC) )
      ALLOCATE(Upham(IROMS,JROMS,NC) )
      ALLOCATE(Vampm(IROMS,JROMS,NC) )
      ALLOCATE(Vpham(IROMS,JROMS,NC) )

      ALLOCATE(semam(IROMS,JROMS,NC) )
      ALLOCATE(semim(IROMS,JROMS,NC) )
      ALLOCATE(Aincm(IROMS,JROMS,NC) )
      ALLOCATE (Phim(IROMS,JROMS,NC) )
      ALLOCATE (tidenames(NC) )
      ALLOCATE (tide_period(NC) )
      DO N=1,NC
      DO I=1,IROMS
      DO J=1,JROMS
        semam(I,J,N)=0.0
        semim(I,J,N)=0.0
        Aincm(I,J,N)=0.0
        Phim(I,J,N)=0.0
      ENDDO
      ENDDO
      ENDDO



      STATUS = NF_INQ_VARID(NCID,'tide_names',IDVAR)
      STATUS = NF_GET_VAR_TEXT(NCID,IDVAR,tidenames)
      STATUS = NF_INQ_VARID(NCID,'tide_period',IDVAR)
      STATUS = NF_GET_VAR_REAL(NCID,IDVAR,tide_period)  
      STATUS = NF_INQ_VARID(NCID,'tide_Eamp',IDVAR)
      STATUS = NF_GET_VAR_REAL(NCID,IDVAR,Eampm)  
      STATUS = NF_INQ_VARID(NCID,'tide_Ephase',IDVAR)
      STATUS = NF_GET_VAR_REAL(NCID,IDVAR,Epham)  
      STATUS = NF_INQ_VARID(NCID,'tide_Uamp',IDVAR)
      STATUS = NF_GET_VAR_REAL(NCID,IDVAR,Uampm)  
      STATUS = NF_INQ_VARID(NCID,'tide_Uphase',IDVAR)
      STATUS = NF_GET_VAR_REAL(NCID,IDVAR,Upham)  
      STATUS = NF_INQ_VARID(NCID,'tide_Vamp',IDVAR)
      STATUS = NF_GET_VAR_REAL(NCID,IDVAR,Vampm)  
      STATUS = NF_INQ_VARID(NCID,'tide_Vphase',IDVAR)
      STATUS = NF_GET_VAR_REAL(NCID,IDVAR,Vpham)  
      STATUS=NF_CLOSE(NCID)
!      DO N=1,NC
!	print *,'N=', N,':',tidenames(N),':',360./tide_period(N)
!      ENDDO
      
C apply node factor and equilibrium arguments adjustment to harmonics
      DO N=1,NC
      DO I=1,NWATER
         I8=IWATER(I)
	 J8=JWATER(I)
         Eampm(I8,J8,N)=Eampm(I8,J8,N)*XODE(N)
         Epham(I8,J8,N)=Epham(I8,J8,N)-VPU(N)
         Uampm(I8,J8,N)=Uampm(I8,J8,N)*XODE(N)
         Upham(I8,J8,N)=Upham(I8,J8,N)-VPU(N)
         Vampm(I8,J8,N)=Vampm(I8,J8,N)*XODE(N)
         Vpham(I8,J8,N)=Vpham(I8,J8,N)-VPU(N)
         IF(Epham(I8,J8,N).LT.0.0)Epham(I8,J8,N)=Epham(I8,J8,N)+360.0
         IF( Upham(I8,J8,N) .LT. 0.0)Upham(I8,J8,N)=Upham(I8,J8,N)+360. 	 
         IF( Vpham(I8,J8,N) .LT. 0.0)Vpham(I8,J8,N)=Vpham(I8,J8,N)+360. 	 
      ENDDO
      ENDDO      
!      CALL ap2ep(NWATER,NC,Uampm,Upham,Vampm,Vpham,
!     & Uamp,Upha,Vamp,Vpha)

      DO N=1,NC
      DO I=1,NWATER
           I8=IWATER(I)
	   J8=JWATER(I)
           Uampm0=Uampm(I8,J8,N)
           Upham0=Upham(I8,J8,N)
           Vampm0=Vampm(I8,J8,N)
           Vpham0=Vpham(I8,J8,N)
           CALL ap2ep(Uampm0,Upham0,Vampm0,Vpham0,
     &     semam0,semim0,Aincm0,Phim0)
           semam(I8,J8,N)=semam0
           semim(I8,J8,N)=semim0
           Aincm(I8,J8,N)=Aincm0
           Phim(I8,J8,N)=Phim0
      ENDDO
      ENDDO
      DO I=1,NWATER
           I8=IWATER(I)
	   J8=JWATER(I)
	  write(78,22)I,I8,J8,lonm(I8,j8),latM(i8,J8),Eampm(I8,J8,1),
     &	  Epham(i8,J8,1),semam(I8,J8,1),semim(I8,J8,1),Aincm(I8,J8,1),
     1	  Phim(I8,J8,1)
      ENDDO
22    FORMAT(I8,2I5,2F9.4,6F10.4)


      CALL write_netCDF_tidalforcing_ROMS(GRIDFILE,
     & FOUT,ncid,imode,IROMS,JROMS,NC,IYR,
     & tide_period,tidenames,Epham,Eampm,Phim,Aincm,semim,semam)
      write(*,*)'Tidal forcing NetCDF has been generated successfully'
      write(*,*)'Tidal OBC Forcing file is COMPLETED SUCCESSFULLY'
      STOP	
      END
      subroutine ap2ep(Au,PHIu,Av,PHIv,sema,semi,Ainc,Phi)

! This subroutine was created from the matlab code "ap2ep.m"
! to convert tidal amplitude and phase lag (ap-) parameters into tidal ellipse
! (e-) parameters. Please refer to ep2app for its inverse function.
! 
! Usage:
!
! [SEMA,  ECC, INC, PHA, w]=app2ep(Au, PHIu, Av, PHIv, plot_demo)
!
! input variables:
!
!     Au  : Amplitudes of u tidal current component
!     PHIu: Phase lags (in degrees) of u tidal current component
!     Av  : Amplitudes of v tidal current component
!     PHIv: Phase lags (in degrees) of v tidal current component

! output:
     
!     SEMA: Semi-major axes, or the maximum speed;
!     SEMI  Semi-Minor Axis, or minimum speed
!     ECC:  Eccentricity, the ratio of semi-minor axis over 
!           the semi-major axis; its negative value indicates that the ellipse
!           is traversed in clockwise direction.           
!     INC:  Inclination, the angles (in degrees) between the semi-major 
!           axes and u-axis.                        
!     PHA:  Phase angles, the time (in angles and in degrees) when the 
!           tidal currents reach their maximum speeds,  (i.e. 
!           PHA=omega*tmax).
!          
!           These four e-parameters will have the same dimensionality 
!           (i.e., vectors, or matrices) as the input ap-parameters. 
!
!
      parameter(PI=3.1415926,r2d=180.0/PI)
!      dimension Au(IM,NC),PHIu(IM,NC),Av(IM,NC),PHIv(IM,NC)
!      dimension sema(IM,NC),semi(IM,NC),ecc(IM,NC),
!     & Ainc(IM,NC),PHI(IM,NC)
      complex u,v,wp,wm,z

      call macheps(eps)

!      DO n=1,NC
!      DO I=1,IM
         ANGL=-PHIu*PI/180.
	 AAu=Au* cos(ANGL)
	 BBu=Au* sin(ANGL)
         u=CMPLX(AAu,BBu)

         ANGL=-PHIv*PI/180.
	 AAv=Av* cos(ANGL)
	 BBv=Av* sin(ANGL)
         v=CMPLX(AAv,BBv)

! Calculate complex radius of anticlockwise and clockwise circles:
!   wp = (u+i*v)/2;      % for anticlockwise circles
!   wm = conj(u-i*v)/2;  % for clockwise circles
	 
	 WP=0.5*CMPLX(AAu-BBv,BBu+AAv)
	 WM=0.5*CMPLX(AAu+BBv,AAv-BBu)
         Amp_WP=abs(WP)
         Amp_WM=abs(WM)
	 A1=0.5*(AAu-BBv)
	 B1=0.5*(BBu+AAv)
	 THETA_WP=atan2(B1,A1)*r2d
	 IF(THETA_WP .LT. 0.0)THETA_WP=THETA_WP+360.0
	 
!	 IF( (abs(A1) .LE. eps) .and. (B1 .GT. 0.0) )THETA_WP=0.0
!	 IF( (abs(A1) .LE. eps) .and. (B1 .LT. 0.0) )THETA_WP=180.0
!	 IF( (A1 .GT. 0.0) .and. (abs(B1) .LE. EPS) )THETA_WP=90.0
!	 IF( (A1 .LT. 0.0) .and. (abs(B1) .LE. EPS) )THETA_WP=-90.0
	  
	 A1=0.5*(AAu+BBv)
	 B1=0.5*(AAv-BBu)
	 THETA_WM=atan2(B1,A1)*r2d
	 IF(THETA_WM .LT. 0.0)THETA_WM=THETA_WM+360.0
	 
!	 IF( (abs(A1) .LE. eps) .and. (B1 .GT. 0.0) )THETA_WM=0.0
!	 IF( (abs(A1) .LE. eps) .and. (B1 .LT. 0.0) )THETA_Wm=180.0
!	 IF( (A1 .GT. 0.0) .and. (abs(B1) .LE. EPS) )THETA_WM=90.0
!	 IF( (A1 .LT. 0.0) .and. (abs(B1) .LE. EPS) )THETA_WM=-90.0

         SEMA=Amp_WP + Amp_WM
         SEMI=Amp_WP - Amp_WM
	 ECC=0.0
	 IF(abs(SEMA) .GT. EPS)ECC=SEMI/SEMA
         PHI = (THETA_Wm-THETA_WP)/2.0  ! Phase angle, the time (in angle) when 
                                               ! the velocity reaches the maximum
         AINC = (THETA_WM+THETA_WP)/2.0  ! Inclination, the angle between the 
	 IF(PHI .LT. 0.0)PHI=PHI+360.0
	 IF(AINC .LT. 0.0)AINC=AINC+360.0
                                               ! semi major axis and x-axis (or u-axis).
!      ENDDO
!      ENDDO
      
      END
      
      subroutine macheps(eps)
      eps=1.0
      kbit=0
10    eps=0.5*eps
      kbit=kbit+1
      epsp1=eps+1.
      if((epsp1.gt.1.).and.(epsp1-eps.eq.1.)) goto 10
      if(epsp1-eps.eq.1.)eps=2.*eps
!     write(6,20) eps,kbit
20    format(' eps=',g20.10,' kbit=',i10)
      return
      end

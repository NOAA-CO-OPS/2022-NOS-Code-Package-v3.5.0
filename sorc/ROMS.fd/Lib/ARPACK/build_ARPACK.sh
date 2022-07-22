#!/bin/sh
HOMEnos=/lfs/h1/nos/nosofs/noscrub/$LOGNAME/packages/nosofs.v3.5.0
cd ..
#HOMEnos=`pwd`

BUILD_VERSION_FILE=$HOMEnos/versions/build.ver
if [ -f $BUILD_VERSION_FILE ]; then
 . $BUILD_VERSION_FILE
else
   echo " Build Version File $BUILD_VERSION_FILE does not exist **"
   exit
fi

export HOMEnos=${HOMEnos:-${PACKAGEROOT:?}/nosofs.${nosofs_ver:?}}

export COMP_F=ftn
export COMP_F_MPI90=ftn
export COMP_F_MPI=ftn
export COMP_ICC=cc
export COMP_CC=cc
export COMP_CPP=cpp
export COMP_MPCC=cc

module purge
printenv SHELL
module purge
module load envvar/$envvars_ver
# Loading Intel Compiler Suite
module load PrgEnv-intel/${PrgEnv_intel_ver}
module load craype/${craype_ver}
module load intel/${intel_ver}
module load cray-mpich/${cray_mpich_ver}
module load cray-pals/${cray_pals_ver}
#Set other library variables
#module load netcdf/${netcdf_ver}
#module load hdf5/${hdf5_ver}
module load bacio/${bacio_ver}
module load w3nco/${w3nco_ver}
module load w3emc/${w3emc_ver}
module load g2/${g2_ver}
module load zlib/${zlib_ver}
module load libpng/${libpng_ver}
module load bufr/${bufr_ver}
module load jasper/${jasper_ver}
#
#Set other library variables
module load netcdf/${netcdf_ver}
module load hdf5/${hdf5_ver}
module load subversion/${subversion_ver}

export SORCnos=$HOMEnos/sorc
export EXECnos=$HOMEnos/exec
export LIBnos=$HOMEnos/lib

if [ ! -s $EXECnos ]
then
  mkdir -p $EXECnos
fi
export LIBnos=$HOMEnos/lib

if [ ! -s $LIBnos ]
then
  mkdir -p $LIBnos
fi

# Compile WCOFS_DA
cd $SORCnos/ROMS.fd/Lib/ARPACK
gmake clean
gmake  lib
gmake  plib
gmake clean
#cd $SORCnos/ROMS.fd
#./build_wcofs_da.sh
#gmake clean



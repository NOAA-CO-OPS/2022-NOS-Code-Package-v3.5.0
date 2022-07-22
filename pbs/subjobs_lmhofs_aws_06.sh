#!/bin/bash -l
. /lfs/h1/nos/nosofs/noscrub/aijun.zhang/packages/nosofs.v3.5.0/versions/run.ver
module purge 
module load envvar/${envvars_ver:?}
module load PrgEnv-intel/${PrgEnv_intel_ver}
module load craype/${craype_ver}
module load intel/${intel_ver}
rm -f /lfs/h1/nos/ptmp/aijun.zhang/rpt/v3.5.0/lmhofs_aws_06_prod.out
rm -f /lfs/h1/nos/ptmp/aijun.zhang/rpt/v3.5.0/lmhofs_aws_06_prod.err
export LSFDIR=/lfs/h1/nos/nosofs/noscrub/aijun.zhang/packages/nosofs.v3.5.0/pbs 
qsub $LSFDIR/jnos_lmhofs_aws_06.prod

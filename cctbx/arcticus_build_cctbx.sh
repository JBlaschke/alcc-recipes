#!/bin/bash

set -e
export ALCC_CCTBX_ROOT=$(readlink -f $(dirname ${BASH_SOURCE[0]}))
export OMP_PLACES=threads
export OMP_PROC_BIND=spread
export KOKKOS_DEVICES="OpenMP;SYCL"
export KOKKOS_ARCH="XeHP"

rm -f ${ALCC_CCTBX_ROOT}/activate.sh || true
source ${ALCC_CCTBX_ROOT}/utilities_alcf.sh
#source ${ALCC_CCTBX_ROOT}/opt/site/alcf_arcticus.sh
source ${ALCC_CCTBX_SITE_ARCTICUS}

echo "*"
echo "* Load Sysenv (see log.build_load_sysenv)"
echo "*"
load-sysenv > log.build_load_sysenv 2>&1

echo "*"
echo "* Building CCTBX (see log.mk_cctbx)"
echo "*"
mk-cctbx kokkos-alcf build hot > log.mk_cctbx 2>&1
#patch-dispatcher alcf

cat > ${ALCC_CCTBX_ROOT}/activate.sh << EOF
source ${ALCC_CCTBX_ROOT}/utilities_alcf.sh
source ${ALCC_CCTBX_SITE_ARCTICUS}
load-sysenv
activate

export OMP_PLACES=threads
export OMP_PROC_BIND=spread
export KOKKOS_DEVICES="OpenMP;SYCL"
export KOKKOS_ARCH="XeHP"
#export CUDA_LAUNCH_BLOCKING=1
#export SIT_DATA=\${OVERWRITE_SIT_DATA:-\$NERSC_SIT_DATA}:\$SIT_DATA
#export SIT_PSDM_DATA=\${OVERWRITE_SIT_PSDM_DATA:-\$NERSC_SIT_PSDM_DATA}
#export SIT_ROOT=/reg/g/psdm
EOF

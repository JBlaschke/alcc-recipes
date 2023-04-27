#!/bin/bash

set -e

export ALCC_CCTBX_ROOT=$(readlink -f $(dirname ${BASH_SOURCE[0]}))
export OMP_PLACES=threads
export OMP_PROC_BIND=spread
export KOKKOS_DEVICES="OpenMP;HIP"
export KOKKOS_ARCH="VEGA90A"

source ${ALCC_CCTBX_ROOT}/utilities.sh
source ${ALCC_CCTBX_ROOT}/opt/util/fix_lib_nersc.sh
source ${ALCC_CCTBX_ROOT}/opt/site/olcf_frontier.sh

${ALCC_CCTBX_ROOT}/update_bootstrap.sh

fix-sysversions () {
    env-activate
    if fix-sysversions-cgpu
    then
        return 1
    fi
}

${ALCC_CCTBX_ROOT}/opt/get_mamba_linux-64.sh

load-sysenv

mk-env cray-mpich frontier
if fix-sysversions
then
    return 1
fi
mk-cctbx kokkos build hot update
patch-dispatcher nersc

cat > ${ALCC_CCTBX_ROOT}/activate.sh << EOF
source ${ALCC_CCTBX_ROOT}/utilities.sh
source ${ALCC_CCTBX_ROOT}/opt/site/olcf_frontier.sh
load-sysenv
activate
export OMP_PLACES=threads
export OMP_PROC_BIND=spread
export KOKKOS_DEVICES="OpenMP;HIP"
export KOKKOS_ARCH="VEGA90A"
export SIT_DATA=\${OVERWRITE_SIT_DATA:-\$NERSC_SIT_DAT}:\$SIT_DATA
export SIT_PSDM_DATA=\${OVERWRITE_SIT_PSDM_DATA:-\$NERSC_SIT_PSDM_DATA}
export SIT_ROOT=/reg/g/psdm
EOF

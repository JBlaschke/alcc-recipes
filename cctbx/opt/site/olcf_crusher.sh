#!/bin/bash


load-sysenv () {
module load craype-accel-amd-gfx90a rocm

export MPICH_GPU_SUPPORT_ENABLED=1
}


export NERSC_SIT_DATA=/global/common/software/lcls/psdm/data
export NERSC_SIT_PSDM_DATA=/global/cscratch1/sd/psdatmgr/data/psdm

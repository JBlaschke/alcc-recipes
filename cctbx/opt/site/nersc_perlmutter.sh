#!/bin/bash


load-sysenv () {
    module load PrgEnv-gnu cuda cpe-cuda
}


export NERSC_SIT_DATA=/global/common/software/lcls/psdm/data
export NERSC_SIT_PSDM_DATA=/global/cscratch1/sd/psdatmgr/data/psdm

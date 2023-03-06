#!/usr/bin/env bash

source /img/utilities.sh
source /img/opt/site/nersc_cori.sh

load-sysenv
activate

export SIT_DATA=/global/common/software/lcls/psdm/data:$SIT_DATA
export SIT_PSDM_DATA=/global/cscratch1/sd/psdatmgr/data/psdm
export SIT_ROOT=/reg/g/psdm

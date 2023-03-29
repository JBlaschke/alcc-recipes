#!/usr/bin/env bash

host=$(hostname)
device_0=$(nvidia-smi -L | grep "GPU 0")
echo "${host} ${SLURM_TASK_PID}, ${CUDA_VISIBLE_DEVICES}, ${device_0}"

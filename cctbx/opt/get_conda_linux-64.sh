#!/bin/bash

shopt -s expand_aliases
alias this="readlink -f \$(dirname \${BASH_SOURCE[0]})"
pushd $(this)
wget https://github.com/conda-forge/miniforge/releases/latest/download/Miniforge3-Linux-x86_64.sh
bash Miniforge3-Linux-x86_64.sh -b -p $PWD/mc3
rm Miniforge3-Linux-x86_64.sh

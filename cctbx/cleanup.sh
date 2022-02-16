#!/bin/bash

conda deactivate
\rm -Rf build
\rm -Rf modules
\rm -Rf opt/bin
\rm -Rf opt/mamba
\rm -f log.*
\rm -f activate.sh
\rm -f bootstrap.py
conda env remove -p opt/mamba/envs/psana_env
git checkout opt/mamba

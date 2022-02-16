#!/bin/bash

set -e

./arcticus_create_env.sh
./arcticus_update_modules.sh
./arcticus_build_cctbx.sh

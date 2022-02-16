#!/bin/bash

export ROOT_PREFIX=$(readlink -f $(dirname ${BASH_SOURCE[0]}))
export CONDA_ENV_ROOT=${ROOT_PREFIX}/opt/mamba/envs
export PSANA_ENV=${CONDA_ENV_ROOT}/psana_env
export MAMBA=mamba

setup-env () {
    export CONDA_AUTO_ACTIVATE_BASE=false
    export CC=icx
    export CXX=icpx
    export MPI4PY_CC=icx
    export MPI4PY_MPICC=mpicc
    export CONDA_ROOT="${CONDA_ENV_ROOT}/conda"
    export CONDA_PKGS_DIRS="${CONDA_ROOT}/pkgs"
    export CONDA_ENVS_PATH="${PSANA_ENV}"
    export PYTHONDONTWRITEBYTECODE=1

    CONDA_ENV_CONFIG=intel_py38
    rm -rf ${CONDA_ENV_CONFIG}.yml

    cat >> ${CONDA_ENV_CONFIG}.yml <<EOF
name: ${CONDA_ENV_CONFIG}
channels:
  - /soft/restricted/CNDA/sdk/2021.10.30.001/oneapi/conda_channel
  - intel
  - defaults
  - conda-forge
  - lcls-ii
dependencies:
  - python=3.8
  - mamba
EOF
    \. "$IDPROOT/etc/profile.d/conda.sh" || return $?
}


mk-env () {
    setup-env
    #
    # Install mamba and create the psana_env environment, cloning the Aurora base environment
    #
    echo "*** Creating psana_env environment and installing mamba ***"
    conda env create -p "${PSANA_ENV}" -f ${CONDA_ENV_CONFIG}.yml
    rm ${CONDA_ENV_CONFIG}.yml
    conda activate ${PSANA_ENV}

    echo "*** Updating installation ***"
    ${MAMBA} env update -p ${PSANA_ENV} --file ${ROOT_PREFIX}/alcf_environment.yml 

    #
    # switch MPI backends -- the psana package explicitly downloads openmpi
    # which is incompatible with some systems
    #
    echo "*** Removing mpi4py, mpi, openmpi and mpich ***"
    conda remove --force mpi4py mpi openmpi mpich --yes || true

    echo "*** Removing conflicts in Conda Env and use those from system ***"
    conda remove -p ${PSANA_ENV} -y --force impi_rt || true
    conda remove -p ${PSANA_ENV} -y --force intel-* || true
    conda remove -p ${PSANA_ENV} -y --force dpcpp-cpp-rt || true
    conda remove -p ${PSANA_ENV} -y --force ncurses || true

    echo "*** Installing mpi4py ***"
    if [[ $1 == "aurora-mpich" ]]
    then
            CC=$MPI4PY_CC MPICC=$MPI4PY_MPICC pip install -v --no-cache-dir --no-binary mpi4py mpi4py
    elif [[ $1 == "conda-mpich" ]]
    then
        ${MAMBA} install mpich mpi4py mpich -c defaults --yes
    elif [[ $1 == "mpicc" ]]
    then
        MPICC="$(which mpicc)" pip install --no-binary mpi4py --no-cache-dir \
            mpi4py mpi4py
    elif [[ $1 == "cray-mpich" ]]
    then
        MPICC="cc -shared" pip install --no-binary mpi4py --no-cache-dir \
            mpi4py mpi4py
    elif [[ $1 == "cray-cuda-mpich" ]]
    then
        MPICC="$(which cc) -shared -lcuda -lcudart -lmpi -lgdrapi"\
            pip install --no-binary mpi4py --no-cache-dir mpi4py mpi4py
    elif [[ $1 == "cray-cuda-mpich-perlmutter" ]]
    then
        MPICC="$(which cc) -shared -target-accel=nvidia80 -lmpi -lgdrapi"\
            pip install --no-binary mpi4py --no-cache-dir mpi4py mpi4py
    elif [[ $1 == "cray-hip-mpich" ]]
    then
       MPICC="$(which cc) -shared -lmpi -I${ROCM_PATH}/include -L${ROCM_PATH}/lib -lamdhip64 -lhsa-runtime64"\
           pip install --no-binary mpi4py --no-cache-dir mpi4py mpi4py
    fi

    echo "*** Removing gcc ***"
    conda remove -p ${PSANA_ENV} --yes --force _libgcc_mutex libgcc-ng libstdcxx-ng

    conda deactivate
}


patch-env () {

    python \
        ${ROOT_PREFIX}/opt/util/patch-rpath.py \
        ${PSANA_ENV}/lib

}



patch-env-parallel () {

cat << EOF > $ROOT_PREFIX/opt/util/do_patch.sh
source $ROOT_PREFIX/utilities_alcf.sh
setup-env
${MAMBA} activate patchelf_env
$ROOT_PREFIX/opt/util/patch_all_parallel.sh $PSANA_ENV/lib
EOF

    chmod +x $ROOT_PREFIX/opt/util/do_patch.sh

    echo "Please patch your .so files using Patchelf. Follow these steps:"
    echo "(1) $ salloc --nodes=1 --constraint=haswell --time=30 -A lcls -q interactive"
    echo "(2) $ $ROOT_PREFIX/opt/util/do_patch.sh"

}



env-activate () {
    setup-env
    conda activate ${PSANA_ENV}
}



mk-cctbx () {
    env-activate
    pushd ${ROOT_PREFIX}

    if [[ $1 == "classic" ]]
    then
        python bootstrap.py --builder=dials \
                            --python=37 \
                            --use-conda ${CONDA_PREFIX} \
                            --nproc=${NPROC:-8} \
                            --config-flags="--enable_cxx11" \
                            --config-flags="--no_bin_python" \
                            --config-flags="--enable_openmp_if_possible=True" \
                            --config-flags="--use_environment_flags" \
                            ${@:2}
    elif [[ $1 == "no-boost" ]]
    then
        python bootstrap.py --builder=dials \
                            --python=37 \
                            --use-conda ${CONDA_PREFIX} \
                            --nproc=${NPROC:-8} \
                            --config-flags="--enable_cxx11" \
                            --config-flags="--no_bin_python" \
                            --config-flags="--enable_openmp_if_possible=True" \
                            --config-flags="--use_environment_flags" \
                            --no-boost-src \
                            ${@:2}
    elif [[ $1 == "cuda" ]]
    then
        python bootstrap.py --builder=dials \
                            --python=37 \
                            --use-conda ${CONDA_PREFIX} \
                            --nproc=${NPROC:-8} \
                            --config-flags="--enable_cxx11" \
                            --config-flags="--no_bin_python" \
                            --config-flags="--enable_openmp_if_possible=True" \
                            --config-flags="--enable_cuda" \
                            --config-flags="--use_environment_flags" \
                            ${@:2}
    elif [[ $1 == "kokkos" ]]
    then
        python bootstrap.py --builder=dials \
                            --python=37 \
                            --use-conda ${CONDA_PREFIX} \
                            --nproc=${NPROC:-8} \
                            --config-flags="--enable_cxx11" \
                            --config-flags="--no_bin_python" \
                            --config-flags="--enable_openmp_if_possible=True" \
                            --config-flags="--enable_kokkos" \
                            ${@:2}
    elif [[ $1 == "kokkos-alcf" ]]
    then
        export CTBX_CONDA_USE_ENVIRONMENT_VARIABLES=1
        python bootstrap.py --builder=dials \
                            --python=37 \
                            --use-conda ${CONDA_PREFIX} \
                            --nproc=${NPROC:-32} \
                            --config-flags="--enable_cxx11" \
                            --config-flags="--no_bin_python" \
                            --config-flags="--enable_openmp_if_possible=True" \
                            --config-flags="--enable_kokkos" \
                            --config-flags="--compiler=icpx" \
                            ${@:2}
    fi
    popd
}



patch-dispatcher () {
    activate

    pushd ${ROOT_PREFIX}/build
    ln -fs ${ROOT_PREFIX}/opt/site/dispatcher/dispatcher_include_$1.sh \
           dispatcher_include.sh
    popd

    libtbx.refresh
}



activate () {
    env-activate
    source ${ROOT_PREFIX}/build/setpaths.sh
}

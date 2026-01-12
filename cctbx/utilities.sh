#!/bin/bash



export ROOT_PREFIX=$(readlink -f $(dirname ${BASH_SOURCE[0]}))



setup-env () {
    source ${ROOT_PREFIX}/opt/mc3/etc/profile.d/conda.sh
}



mk-env () {
    setup-env

    native_cc=$(which cc)
    native_CC=$(which CC)

    if [[ $2 == "perlmutter" ]]
    then
        conda env create -f ${ROOT_PREFIX}/perlmutter_environment.yml -p ${ROOT_PREFIX}/opt/envs/psana_env --yes
    elif [[ $2 == "frontier" ]]
    then
        conda env create -f ${ROOT_PREFIX}/frontier_environment.yml -p ${ROOT_PREFIX}/opt/envs/psana_env --yes
    else
        conda env create -f ${ROOT_PREFIX}/psana_environment.yml -p ${ROOT_PREFIX}/opt/envs/psana_env --yes
    fi

    # switch MPI backends -- the psana package explicitly downloads openmpi
    # which is incompatible with some systems
    conda activate ${ROOT_PREFIX}/opt/envs/psana_env
    conda remove --force mpi4py mpi openmpi --yes || true
    # mpich may not be present, but if it is, we remove that too
    conda remove --force mpich --yes || true
    # Same for libfabric, which comes in with psana-ii and shadows the cray version
    conda remove --force libfabric --yes || true

    echo "MPI4PY build using native_cc=${native_cc} native_CC=${native_CC}"

    if [[ $1 == "conda-mpich" ]]
    then
        conda install mpich mpi4py mpich -c defaults --yes
    elif [[ $1 == "mpicc" ]]
    then
        MPICC="$(which mpicc)" pip install --no-binary mpi4py --no-cache-dir \
            mpi4py mpi4py
    elif [[ $1 == "cray-mpich" ]]
    then
        MPICC="${native_cc} -shared" pip install --no-binary mpi4py --no-cache-dir \
            mpi4py mpi4py
    elif [[ $1 == "cray-cuda-mpich" ]]
    then
        MPICC="${native_cc} -shared -lcuda -lcudart -lmpi -lgdrapi"\
            pip install --no-binary mpi4py --no-cache-dir mpi4py mpi4py
    elif [[ $1 == "cray-cuda-mpich-perlmutter" ]]
    then
        MPICC="${native_cc} -shared -target-accel=nvidia80 -lmpi -lgdrapi"\
            pip install --no-binary mpi4py --no-cache-dir mpi4py mpi4py
    elif [[ $1 == "cray-hip-mpich" ]]
    then
       MPICC="${native_cc} -shared -lmpi -I${ROCM_PATH}/include -L${ROCM_PATH}/lib -lamdhip64 -lhsa-runtime64"\
           pip install --no-binary mpi4py --no-cache-dir mpi4py mpi4py
    fi

    conda deactivate
}



patch-env () {

    python \
        ${ROOT_PREFIX}/opt/util/patch-rpath.py \
        ${MAMBA_ROOT_PREFIX}/envs/psana_env/lib

}



patch-env-parallel () {

cat << EOF > $ROOT_PREFIX/opt/util/do_patch.sh
source $ROOT_PREFIX/utilities.sh
setup-env
conda activate patchelf_env
$ROOT_PREFIX/opt/util/patch_all_parallel.sh $MAMBA_ROOT_PREFIX/envs/psana_env/lib
EOF

    chmod +x $ROOT_PREFIX/opt/util/do_patch.sh

    echo "Please patch your .so files using Patchelf. Follow these steps:"
    echo "(1) $ salloc --nodes=1 --constraint=haswell --time=30 -A lcls -q interactive"
    echo "(2) $ $ROOT_PREFIX/opt/util/do_patch.sh"

}



env-activate () {
    setup-env
    conda activate ${ROOT_PREFIX}/opt/envs/psana_env
}



mk-cctbx () {
    env-activate

    pushd ${ROOT_PREFIX}

    gcc --version

    if [[ $1 == "classic" ]]
    then
        python bootstrap.py --builder=dials \
                            --python=310 \
                            --use-conda ${CONDA_PREFIX} \
                            --nproc=${NPROC:-8} \
                            --config-flags="--cxxstd=c++14" \
                            --config-flags="--no_bin_python" \
                            --config-flags="--enable_openmp_if_possible=True" \
                            --config-flags="--use_environment_flags" \
                            --no-boost-src \
                            ${@:2}
    elif [[ $1 == "no-boost" ]]
    then
        python bootstrap.py --builder=dials \
                            --python=310 \
                            --use-conda ${CONDA_PREFIX} \
                            --nproc=${NPROC:-8} \
                            --config-flags="--cxxstd=c++14" \
                            --config-flags="--no_bin_python" \
                            --config-flags="--enable_openmp_if_possible=True" \
                            --config-flags="--use_environment_flags" \
                            --no-boost-src \
                            ${@:2}
    elif [[ $1 == "cuda" ]]
    then
        python bootstrap.py --builder=dials \
                            --python=310 \
                            --use-conda ${CONDA_PREFIX} \
                            --nproc=${NPROC:-8} \
                            --config-flags="--cxxstd=c++14" \
                            --config-flags="--no_bin_python" \
                            --config-flags="--enable_openmp_if_possible=True" \
                            --config-flags="--enable_cuda" \
                            --config-flags="--enable_kokkos" \
                            --config-flags="--use_environment_flags" \
                            --no-boost-src \
                            ${@:2}
    elif [[ $1 == "kokkos" ]]
    then
        python bootstrap.py --builder=dials \
                            --python=310 \
                            --use-conda ${CONDA_PREFIX} \
                            --nproc=${NPROC:-8} \
                            --config-flags="--cxxstd=c++14" \
                            --config-flags="--no_bin_python" \
                            --config-flags="--enable_openmp_if_possible=True" \
                            --config-flags="--enable_kokkos" \
                            --config-flags="--use_environment_flags" \
                            --no-boost-src \
                            ${@:2}
    elif [[ $1 == "kokkos_NOOMP" ]]
    then
        python bootstrap.py --builder=dials \
                            --python=310 \
                            --use-conda ${CONDA_PREFIX} \
                            --nproc=${NPROC:-8} \
                            --config-flags="--cxxstd=c++14" \
                            --config-flags="--no_bin_python" \
                            --config-flags="--enable_openmp_if_possible=False" \
                            --config-flags="--enable_kokkos" \
                            --config-flags="--use_environment_flags" \
                            --no-boost-src \
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

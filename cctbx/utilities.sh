#!/bin/bash



export ROOT_PREFIX=$(readlink -f $(dirname ${BASH_SOURCE[0]}))



setup-env () {
    export MAMBA_ROOT_PREFIX=${ROOT_PREFIX}/opt/mamba
    eval "$(${ROOT_PREFIX}/opt/bin/micromamba shell hook -s bash)"
}



mk-env () {
    setup-env

    micromamba activate
    micromamba install python=3.9 -c defaults --yes

    if [[ $2 == "perlmutter" ]]
    then
        micromamba create -f ${ROOT_PREFIX}/perlmutter_environment.yml --yes
    else
        micromamba create -f ${ROOT_PREFIX}/psana_environment.yml --yes
    fi

    # switch MPI backends -- the psana package explicitly downloads openmpi
    # which is incompatible with some systems
    micromamba activate psana_env
    # HACK: mamba/micromamba does not support --force removal yet
    # https://github.com/mamba-org/mamba/issues/412
    micromamba install conda -c defaults --yes
    conda remove --force mpi4py mpi openmpi mpich --yes || true
    if [[ $1 == "conda-mpich" ]]
    then
        micromamba install mpich mpi4py mpich -c defaults --yes
    elif [[ $1 == "mpicc" ]]
    then
        # TODO: Hack away the mamba/conda linker
        mv /img/opt/mamba/envs/psana_env/compiler_compat \
            /img/opt/mamba/envs/psana_env/compiler_compat.moveaside
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
    fi

    micromamba deactivate
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
micromamba activate patchelf_env
$ROOT_PREFIX/opt/util/patch_all_parallel.sh $MAMBA_ROOT_PREFIX/envs/psana_env/lib
EOF

    chmod +x $ROOT_PREFIX/opt/util/do_patch.sh

    echo "Please patch your .so files using Patchelf. Follow these steps:"
    echo "(1) $ salloc --nodes=1 --constraint=haswell --time=30 -A lcls -q interactive"
    echo "(2) $ $ROOT_PREFIX/opt/util/do_patch.sh"

}



env-activate () {
    setup-env
    micromamba activate psana_env
}



mk-cctbx () {
    env-activate

    pushd ${ROOT_PREFIX}

    if [[ $1 == "classic" ]]
    then
        python bootstrap.py --builder=dials \
                            --python=39 \
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
                            --python=39 \
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
                            --python=39 \
                            --use-conda ${CONDA_PREFIX} \
                            --nproc=${NPROC:-8} \
                            --config-flags="--enable_cxx11" \
                            --config-flags="--no_bin_python" \
                            --config-flags="--enable_openmp_if_possible=True" \
                            --config-flags="--enable_cuda" \
                            --config-flags="--use_environment_flags" \
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

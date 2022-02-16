#!/bin/bash


fix_lib () {

    __fix_lib_link () {

        blacklist=(ssl crypto krb5 stdc++)
        fn=$(basename -- $1)

        for bl in ${blacklist[@]}
        do
            if [[ $fn == *${bl}* ]]
            then
                return 1
            fi
        done

        if [[ -e $fn ]]
        then
            echo "Overwriting: $fn with $1" >> fix_lib.log
            mv $fn fix_lib_moveasie/
        fi

        ln -sf $1

        return 0
    }

    mkdir -p fix_lib_moveasie

    for so_file in $1/*.so
    do
        __fix_lib_link $so_file
    done

    for so_file in $1/*.so.*
    do
        __fix_lib_link $so_file
    done
}



fix-sysversions-cgpu () {

    if ! [[ -d ${GCC_ROOT}/lib64 ]]
    then
        echo "Could not find GCC library dir"
        return 1
    fi

    if ! [[ -d ${OPENMPI_DIR}/lib ]]
    then
        echo "Could not find OpenMPI library dir"
        return 1
    fi


    if [[ -d $CONDA_PREFIX ]]
    then
        pushd $CONDA_PREFIX/lib

        fix_lib /usr/lib64
        fix_lib /lib64
        fix_lib ${OPENMPI_DIR}/lib
        fix_lib ${GCC_ROOT}/lib64

        popd

        return 0
    else
        echo "Could not find target conda library"
        return 1
    fi
}



fix-sysversions-perlmutter () {

    if ! [[ -d ${GCC_ROOT}/lib64 ]]
    then
        echo "Could not find GCC library dir"
        return 1
    fi

    if ! [[ -d ${OPENMPI_DIR}/lib ]]
    then
        echo "Could not find OpenMPI library dir"
        return 1
    fi


    if [[ -d $CONDA_PREFIX ]]
    then
        pushd $CONDA_PREFIX/lib

        fix_lib /usr/lib64
        fix_lib /lib64
        fix_lib ${CRAY_MPICH_PREFIX}/lib
        fix_lib ${CRAY_MPICH_PREFIX}/lib-abi-mpich
        fix_lib ${GCC_PREFIX}/snos/lib64

        popd

        return 0
    else
        echo "Could not find target conda library"
        return 1
    fi
}



fix-sysversions-arcticus () {

    if ! [[ -d ${GCC_ROOT}/lib64 ]]
    then
        echo "Could not find GCC library dir"
        return 1
    fi

    if ! [[ -d ${OPENMPI_DIR}/lib ]]
    then
        echo "Could not find OpenMPI library dir"
        return 1
    fi


    if [[ -d $CONDA_PREFIX ]]
    then
        pushd $CONDA_PREFIX/lib

        fix_lib /usr/lib64
        fix_lib /lib64
        fix_lib ${CRAY_MPICH_PREFIX}/lib
        fix_lib ${CRAY_MPICH_PREFIX}/lib-abi-mpich
        fix_lib ${GCC_PREFIX}/snos/lib64

        popd

        return 0
    else
        echo "Could not find target conda library"
        return 1
    fi
}

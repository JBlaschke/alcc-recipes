FROM ubuntu:20.04
LABEL maintainer="Johannes Blaschke <jpblaschke@lbl.gov>"

# Base Ubuntu packages

ENV DEBIAN_FRONTEND noninteractive
ENV LANG C.UTF-8

RUN \
    apt-get update          &&                                                 \
    apt-get --yes upgrade   &&                                                 \
    apt-get --yes install                                                      \
        bzip2                                                                  \
        curl                                                                   \
        git                                                                    \
        libffi-dev                                                             \
        lsb-release                                                            \
        tzdata                                                                 \
        vim neovim                                                             \
        wget                                                                   \
        bash fish                                                              \
        autoconf automake make cmake                                           \
        gcc g++ gfortran build-essential                                       \
        tar unzip                                                              \
        strace                                                                 \
        patchelf                                                               \
        python3 python3-dev pip                                                \
        libgl1-mesa-dev libglu1-mesa-dev                                       \
        libgtk2.0-0                                                            \
        x11-xserver-utils                                                      \
        xclip xfonts-utils                                                     \
        gettext                                                                \
        libtool libtool-bin                                                    \
        lua5.3                                                                 \
        ninja-build                                                            \
        pkg-config                                                             \
        cscope                                                                 \
        nodejs npm                                                             \
    && apt-get clean all

RUN update-alternatives --install /usr/bin/python python /usr/bin/python3 10

# Timezone to Berkeley
ENV TZ=America/Los_Angeles
RUN \
    ln -snf /usr/share/zoneinfo/$TZ /etc/localtime  &&  \
    echo $TZ > /etc/timezone


#-------------------------------------------------------------------------------
# Make COMMON WORKSPACE (that won't be clobbered by Shifter)
#

RUN mkdir -p /shft
RUN mkdir -p /img

#-------------------------------------------------------------------------------


#-------------------------------------------------------------------------------
# Add MPICH
#

RUN mkdir -p /shft/app
WORKDIR /shft/app

ARG mpich=3.3
ARG mpich_prefix=mpich-$mpich

USER root
RUN \
    wget https://www.mpich.org/static/downloads/$mpich/$mpich_prefix.tar.gz && \
    tar xvzf $mpich_prefix.tar.gz                                           && \
    cd $mpich_prefix                                                        && \
    ./configure                                                             && \
    make -j 4                                                               && \
    make install                                                            && \
    make clean                                                              && \
    cd ..                                                                   && \
    rm -rf $mpich_prefix

#-------------------------------------------------------------------------------


#-------------------------------------------------------------------------------
# SET up non-root USER and location for image contents
#

RUN groupadd -r user && useradd -r -g user user
RUN usermod -d /shft/home user
RUN chown user /shft
RUN chown user /img
USER user
RUN mkdir -p /shft/home

#-------------------------------------------------------------------------------


#-------------------------------------------------------------------------------
# SPACEVIM Setup
#

ENV HOME /shft/home
WORKDIR $HOME

COPY --chown=user docker/SpaceVim.d $HOME/.SpaceVim.d
RUN curl -sLf https://spacevim.org/install.sh | bash
RUN nvim --headless +'call dein#install()' +qall

#-------------------------------------------------------------------------------


#-------------------------------------------------------------------------------
# SHELL and WORKDIR
#
# The /opt/ scripts require source => switch `RUN` to execute bash (instead sh)
#

SHELL ["/bin/bash", "-c"]
WORKDIR /img

#-------------------------------------------------------------------------------


#-------------------------------------------------------------------------------
# BUILD CCTBX
#

COPY --chown=user cctbx /img

RUN cd /img                                                                 && \
    ./opt/get_mamba_linux-64.sh

RUN cd /img                                                                 && \
    source utilities.sh                                                     && \
    mk-env mpicc

RUN cd /img                                                                 && \
    ./update_bootstrap.sh                                                   && \
    source utilities.sh                                                     && \
    export NPROC=$(nproc)                                                   && \
    mk-cctbx classic

RUN cd /img                                                                 && \
    source utilities.sh                                                     && \
    setup-env                                                               && \
    patch-env

RUN cd /img                                                                 && \
    source utilities.sh                                                     && \
    activate                                                                && \
    patch-dispatcher docker

RUN cd /img                                                                 && \
    source utilities.sh                                                     && \
    activate                                                                && \
    micromamba clean -ay

#-------------------------------------------------------------------------------


#-------------------------------------------------------------------------------
# LDCONFIG
#
# We recommend running an /sbin/ldconfig as part of the image build (e.g. in
# the Dockerfile) to update the cache after installing any new libraries in in
# the image build.
#

USER root
RUN /sbin/ldconfig
USER user

#-------------------------------------------------------------------------------


#-------------------------------------------------------------------------------
# ENTRYPOINT
#

ADD --chown=user docker/entrypoint.sh /img
RUN chmod +x entrypoint.sh

ENTRYPOINT ["/img/entrypoint.sh"]

#-------------------------------------------------------------------------------

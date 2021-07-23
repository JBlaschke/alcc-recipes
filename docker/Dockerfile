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
        gcc g++ gfortran                                                       \
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
# SPACEVIM Setup
#

ENV HOME /root
WORKDIR $HOME

COPY docker/SpaceVim.d $HOME/.SpaceVim.d
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

RUN mkdir -p /img
COPY cctbx /img

RUN cd /img                                                                 && \
    ./opt/get_mamba_linux-64.sh

RUN cd /img                                                                 && \
    source utilities.sh                                                     && \
    mk-env conda-mpich

RUN cd /img                                                                 && \
    source utilities.sh                                                     && \
    export NPROC=$(nproc)                                                   && \
    mk-cctbx classic

# RUN cd /img                                                                 && \
#     source utilities.sh                                                     && \
#     activate                                                                && \
#     patch-dispatcher docker
# 
# RUN cd /img                                                                 && \
#     source utilities.sh                                                     && \
#     activate                                                                && \
#     micromamba clean -ay

#-------------------------------------------------------------------------------


# #-------------------------------------------------------------------------------
# # LDCONFIG
# #
# # We recommend running an /sbin/ldconfig as part of the image build (e.g. in
# # the Dockerfile) to update the cache after installing any new libraries in in
# # the image build.
# #
# 
# RUN /sbin/ldconfig
# 
# #-------------------------------------------------------------------------------
# 
# 
# #-------------------------------------------------------------------------------
# # ENTRYPOINT
# #
# 
# RUN chmod +x entrypoint.sh
# 
# ENTRYPOINT ["/img/entrypoint.sh"]
# 
# #-------------------------------------------------------------------------------
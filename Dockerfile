# Dockerfile for OpenFOAM 6 and ParaView 5.4 with Intel MPI 5.1 on CentOS 7 for use with Batch Shipyard on Azure Batch.
# Based on https://github.com/Azure/batch-shipyard/blob/master/recipes/OpenFOAM-Infiniband-IntelMPI/docker/Dockerfile

FROM centos:7.6.1810 AS build

# Install build packages
RUN yum install -y epel-release \
    && yum install -y \
    boost-devel \
    cmake3 \
    dapl \
    flex \
    gcc \
    gcc-c++ \
    gnuplot \
    libGLU-devel \
    libXt-devel \
    libibverbs \
    libmlx4 \
    librdmacm \
    make \
    man \
    mesa-libGL-devel \
    mpfr-devel \
    ncurses-devel \
    net-tools \
    qt-x11 \
    qt4-devel \
    qtwebkit-devel \
    rdma \
    readline-devel \
    zlib-devel \
    && yum clean all

# Configure cmake alias
RUN alternatives --install /usr/local/bin/cmake cmake /usr/bin/cmake3 10 \
    --slave /usr/local/bin/ctest ctest /usr/bin/ctest3 \
    --slave /usr/local/bin/cpack cpack /usr/bin/cpack3 \
    --slave /usr/local/bin/ccmake ccmake /usr/bin/ccmake3 \
    --family cmake

# Install Intel MPI 5.1
ADD http://registrationcenter-download.intel.com/akdlm/irc_nas/tec/9278/l_mpi_p_5.1.3.223.tgz /tmp/
WORKDIR /tmp
RUN tar zxvf l_mpi_p_5.1.3.223.tgz \
    && cd l_mpi_p_5.1.3.223 \
    && sed -i 's/ACCEPT_EULA=decline/ACCEPT_EULA=accept/' silent.cfg \
    && sed -i 's/ACTIVATION_TYPE=exist_lic/ACTIVATION_TYPE=trial_lic/' silent.cfg \
    && ./install.sh -s silent.cfg \
    && rm -rf \
    /tmp/l_mpi_p_5.1.3.223 \
    /tmp/l_mpi_p_5.1.3.223.tgz \
    /opt/intel/documentation_2016 \
    /opt/intel/ism \
    /opt/intel/parallel_studio_xe_2016.3.068

# Set environment variables
ENV MPI_ROOT=/opt/intel/compilers_and_libraries/linux/mpi \
    PATH=$PATH:/usr/lib64/qt4/bin

# Download and build OpenFOAM-6 and ThirdParty-6 components from source
WORKDIR /opt/OpenFOAM
RUN curl -L http://dl.openfoam.org/source/6 | tar xvz \
    && curl -L http://dl.openfoam.org/third-party/6 | tar xvz \
    && mv OpenFOAM-6-version-6 OpenFOAM-6 \
    && mv ThirdParty-6-version-6 ThirdParty-6 \
    && sed -i 's/FOAM_INST_DIR=$HOME\/\$WM_PROJECT/FOAM_INST_DIR=\/opt\/\$WM_PROJECT/' /opt/OpenFOAM/OpenFOAM-6/etc/bashrc \
    && sed -i 's/export WM_MPLIB=SYSTEMOPENMPI/export WM_MPLIB=INTELMPI/' /opt/OpenFOAM/OpenFOAM-6/etc/bashrc \
    && source /opt/intel/bin/compilervars.sh intel64 \
    && source $MPI_ROOT/bin64/mpivars.sh intel64 \
    && source /opt/OpenFOAM/OpenFOAM-6/etc/bashrc \
    && /opt/OpenFOAM/ThirdParty-6/Allwmake \
    && /opt/OpenFOAM/ThirdParty-6/makeParaView -config \
    && sed -i '/DOCUMENTATION_DIR "\${CMAKE_CURRENT_SOURCE_DIR}\/doc"/d' /opt/OpenFOAM/ThirdParty-6/ParaView-5.4.0/Plugins/StreamLinesRepresentation/CMakeLists.txt \
    && /opt/OpenFOAM/ThirdParty-6/makeParaView \
    && wmRefresh \
    && /opt/OpenFOAM/OpenFOAM-6/Allwmake -j \
    # Remove intermediate build files
    && rm -rf \
    /opt/OpenFOAM/OpenFOAM-6/platforms/*/applications \
    /opt/OpenFOAM/OpenFOAM-6/platforms/*/src \
    /opt/OpenFOAM/ThirdParty-6/build \
    /opt/OpenFOAM/ThirdParty-6/gcc-* \
    /opt/OpenFOAM/ThirdParty-6/gmp-* \
    /opt/OpenFOAM/ThirdParty-6/mpfr-* \
    /opt/OpenFOAM/ThirdParty-6/binutils-* \
    /opt/OpenFOAM/ThirdParty-6/boost* \
    /opt/OpenFOAM/ThirdParty-6/ParaView-* \
    /opt/OpenFOAM/ThirdParty-6/qt-*

# Multi-stage build to reduce final image size
FROM centos:7.6.1810
LABEL maintainer="Richard Lock <https://github.com/richardlock>"

# Set MPI_ROOT environment variable
ENV MPI_ROOT=/opt/intel/compilers_and_libraries/linux/mpi

# Setup ssh
COPY ssh_config /root/.ssh/config
RUN yum swap -y fakesystemd systemd \
    && yum install -y openssh-clients openssh-server \
    && yum clean all \
    && mkdir -p /var/run/sshd \
    && ssh-keygen -A \
    && sed -i 's/UsePAM yes/UsePAM no/g' /etc/ssh/sshd_config \
    && sed -i 's/#PermitRootLogin yes/PermitRootLogin yes/g' /etc/ssh/sshd_config \
    && sed -i 's/#RSAAuthentication yes/RSAAuthentication yes/g' /etc/ssh/sshd_config \
    && sed -i 's/#PubkeyAuthentication yes/PubkeyAuthentication yes/g' /etc/ssh/sshd_config \
    && ssh-keygen -f /root/.ssh/id_rsa -t rsa -N '' \
    && chmod 600 /root/.ssh/config \
    && chmod 700 /root/.ssh \
    && cp /root/.ssh/id_rsa.pub /root/.ssh/authorized_keys

# Copy OpenFOAM and Intel MPI from /opt in build image
COPY --from=build /opt /opt

# Setup sshd on port 23
EXPOSE 23
CMD ["/usr/sbin/sshd", "-D", "-p", "23"]
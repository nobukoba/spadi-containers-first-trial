# syntax=docker/dockerfile:1

FROM quay.io/almalinuxorg/9-base:9 AS artemis-build

ARG NPROC=4
ARG ROOT_VERSION=v6-32-06
ARG ARTEMIS_BRANCH=develop
ARG LIBZMQ_VERSION=v4.3.5
ARG HIREDIS_VERSION=v1.1.0
ARG REDIS_PLUS_PLUS_VERSION=1.3.6
ARG YAML_CPP_VERSION=0.8.0

ENV SPADI_ROOT=/opt/spadi
ENV ROOTSYS=/opt/spadi
ENV ARTEMIS_ROOT=/opt/spadi
ENV TARTSYS=/opt/spadi
ENV PATH=/opt/spadi/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
ENV LD_LIBRARY_PATH=/opt/spadi/lib:/opt/spadi/lib64
ENV CMAKE_PREFIX_PATH=/opt/spadi
ENV PKG_CONFIG_PATH=/opt/spadi/lib/pkgconfig:/opt/spadi/lib64/pkgconfig
ENV CFLAGS="-O2 -march=x86-64 -mtune=generic -mno-avx -mno-avx2"
ENV CXXFLAGS="-O2 -march=x86-64 -mtune=generic -mno-avx -mno-avx2"

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

RUN dnf -y update && \
    dnf -y install dnf-plugins-core && \
    dnf config-manager --set-enabled crb && \
    dnf -y install \
      git gcc gcc-c++ gcc-gfortran make cmake ninja-build pkgconf-pkg-config \
      which findutils diffutils patch tar gzip bzip2 xz unzip \
      wget ca-certificates python3 python3-pip rsync \
      binutils file procps-ng tmux vim-minimal \
      openssl-devel zlib-devel xz-devel bzip2-devel pcre2-devel \
      libX11-devel libXext-devel libXft-devel libXpm-devel libXrender-devel \
      libjpeg-turbo-devel libpng-devel freetype-devel giflib-devel \
      mesa-libGL-devel mesa-libGLU-devel \
      libuuid-devel sqlite-devel \
      openmpi openmpi-devel && \
    dnf clean all && rm -rf /var/cache/dnf

RUN mkdir -p \
      /opt/spadi/src \
      /opt/spadi/scripts/local \
      /workspace && \
    chmod 1777 /workspace

# ROOT, ARTEMIS, and their locally built dependencies all install directly
# into /opt/spadi. ROOT's gnuinstall layout would place scripts under
# /opt/spadi/etc/root, so keep ROOT's native layout while sharing the same
# top-level prefix with ARTEMIS and the other SPADI software.
RUN cd /opt/spadi/src && \
    git clone --depth 1 --branch ${ROOT_VERSION} https://github.com/root-project/root.git && \
    cmake -S root -B root-build \
      -DCMAKE_BUILD_TYPE=Release \
      -DCMAKE_INSTALL_PREFIX=/opt/spadi \
      -DCMAKE_C_FLAGS_RELEASE="-O2 -DNDEBUG -march=x86-64 -mtune=generic -mno-avx -mno-avx2" \
      -DCMAKE_CXX_FLAGS_RELEASE="-O2 -DNDEBUG -march=x86-64 -mtune=generic -mno-avx -mno-avx2" \
      -Dgnuinstall=OFF -Dtesting=OFF -Dtmva=ON -Droofit=OFF -Dpyroot=OFF \
      -Dwebgui=OFF -Dxrootd=OFF -Ddavix=OFF -Dmysql=OFF -Dpgsql=OFF \
      -Dodbc=OFF -Dsqlite=ON -Dssl=ON -Dx11=ON -Dopengl=ON && \
    cmake --build root-build -j${NPROC} && \
    cmake --install root-build

RUN cd /opt/spadi/src && \
    git clone --depth 1 --branch ${YAML_CPP_VERSION} https://github.com/jbeder/yaml-cpp.git && \
    cmake -S yaml-cpp -B yaml-cpp/build \
      -DCMAKE_BUILD_TYPE=Release \
      -DCMAKE_INSTALL_PREFIX=/opt/spadi \
      -DCMAKE_INSTALL_LIBDIR=lib \
      -DYAML_BUILD_SHARED_LIBS=ON \
      -DYAML_CPP_BUILD_TESTS=OFF \
      -DYAML_CPP_BUILD_TOOLS=OFF && \
    cmake --build yaml-cpp/build -j${NPROC} && \
    cmake --install yaml-cpp/build

RUN cd /opt/spadi/src && \
    git clone --depth 1 --branch ${LIBZMQ_VERSION} https://github.com/zeromq/libzmq.git && \
    cmake -S libzmq -B libzmq/build \
      -DCMAKE_BUILD_TYPE=Release \
      -DCMAKE_INSTALL_PREFIX=/opt/spadi \
      -DCMAKE_INSTALL_LIBDIR=lib \
      -DCMAKE_POSITION_INDEPENDENT_CODE=ON \
      -DBUILD_TESTS=OFF \
      -DENABLE_DRAFTS=OFF && \
    cmake --build libzmq/build -j${NPROC} && \
    cmake --install libzmq/build

RUN cd /opt/spadi/src && \
    git clone --depth 1 --branch ${HIREDIS_VERSION} https://github.com/redis/hiredis.git && \
    make -C hiredis -j${NPROC} PREFIX=/opt/spadi LIBRARY_PATH=lib && \
    make -C hiredis PREFIX=/opt/spadi LIBRARY_PATH=lib install && \
    test -e /opt/spadi/lib/libhiredis.so

RUN cd /opt/spadi/src && \
    git clone --depth 1 --branch ${REDIS_PLUS_PLUS_VERSION} https://github.com/sewenew/redis-plus-plus.git && \
    sed -i '/#include "cxx_utils.h"/i #include <cstdint>' redis-plus-plus/src/sw/redis++/utils.h && \
    cmake -S redis-plus-plus -B redis-plus-plus/build \
      -DCMAKE_BUILD_TYPE=Release \
      -DCMAKE_INSTALL_PREFIX=/opt/spadi \
      -DCMAKE_INSTALL_LIBDIR=lib \
      -DCMAKE_PREFIX_PATH=/opt/spadi \
      -DCMAKE_POSITION_INDEPENDENT_CODE=ON \
      -DREDIS_PLUS_PLUS_CXX_STANDARD=17 \
      -DREDIS_PLUS_PLUS_BUILD_TEST=OFF \
      -DREDIS_PLUS_PLUS_BUILD_STATIC=OFF && \
    cmake --build redis-plus-plus/build -j${NPROC} && \
    cmake --install redis-plus-plus/build

RUN cd /opt/spadi/src && \
    git clone --depth 1 --branch ${ARTEMIS_BRANCH} https://github.com/artemis-dev/artemis.git && \
    cmake -S artemis -B artemis/build \
      -DCMAKE_BUILD_TYPE=Release \
      -DCMAKE_INSTALL_PREFIX=/opt/spadi \
      -DCMAKE_PREFIX_PATH=/opt/spadi \
      -DBUILD_GET=OFF \
      -DBUILD_WITH_ZMQ=ON \
      -DBUILD_WITH_REDIS=ON && \
    cmake --build artemis/build -j${NPROC} --verbose && \
    cmake --install artemis/build

RUN printf '%s\n' '/opt/spadi/lib' '/opt/spadi/lib64' > /etc/ld.so.conf.d/spadi.conf && \
    ldconfig && \
    test -r /opt/spadi/bin/thisroot.sh && \
    test -r /opt/spadi/bin/thisartemis.sh && \
    root-config --version && \
    test -x /opt/spadi/bin/artemis

COPY scripts/smoke-test-artemis.sh /opt/spadi/scripts/smoke-test-artemis.sh
RUN chmod 0755 /opt/spadi/scripts/smoke-test-artemis.sh

WORKDIR /workspace

FROM artemis-build AS devel-artemis
ENV SPADI_IMAGE_KIND=devel
CMD ["/bin/bash"]

FROM artemis-build AS artemis-runtime-files
# ROOT/Cling needs the installed headers, including ROOT.modulemap, at runtime.
# Remove source trees from the user image, but keep /opt/spadi/include.
RUN rm -rf /opt/spadi/src

FROM quay.io/almalinuxorg/9-base:9 AS user-artemis

ENV SPADI_ROOT=/opt/spadi
ENV ROOTSYS=/opt/spadi
ENV ARTEMIS_ROOT=/opt/spadi
ENV TARTSYS=/opt/spadi
ENV SPADI_IMAGE_KIND=user
ENV PATH=/opt/spadi/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
ENV LD_LIBRARY_PATH=/opt/spadi/lib:/opt/spadi/lib64
ENV CMAKE_PREFIX_PATH=/opt/spadi
ENV PKG_CONFIG_PATH=/opt/spadi/lib/pkgconfig:/opt/spadi/lib64/pkgconfig

RUN dnf -y update && \
    dnf -y install dnf-plugins-core && \
    dnf config-manager --set-enabled crb && \
    dnf -y install \
      which findutils procps-ng tmux ca-certificates gcc-c++ \
      openssl-libs zlib xz-libs bzip2-libs pcre2 \
      libX11 libXext libXft libXpm libXrender \
      libjpeg-turbo libpng freetype giflib \
      mesa-libGL mesa-libGLU \
      libuuid sqlite-libs openmpi && \
    dnf clean all && rm -rf /var/cache/dnf

COPY --from=artemis-runtime-files /opt/spadi /opt/spadi

RUN mkdir -p /workspace && chmod 1777 /workspace && \
    printf '%s\n' '/opt/spadi/lib' '/opt/spadi/lib64' > /etc/ld.so.conf.d/spadi.conf && \
    ldconfig

WORKDIR /workspace
CMD ["/bin/bash"]

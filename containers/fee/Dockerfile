# syntax=docker/dockerfile:1

FROM almalinux:9 AS fee-build

ARG NPROC=4
ARG HUL_COMMON_LIB_REF=main
ARG AMANEQ_SOFT_REF=main
ARG OPENFPGALOADER_REF=master
ARG SITCP_IP_UTILITY_REF=75353888d15381bb03ce5bfea410851a832ef9a7

ENV SPADI_ROOT=/opt/spadi
ENV PATH=/opt/spadi/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
ENV LD_LIBRARY_PATH=/opt/spadi/lib:/opt/spadi/lib64
ENV CMAKE_PREFIX_PATH=/opt/spadi
ENV PKG_CONFIG_PATH=/opt/spadi/lib/pkgconfig:/opt/spadi/lib64/pkgconfig
ENV CFLAGS="-O2 -march=x86-64 -mtune=generic"
ENV CXXFLAGS="-O2 -march=x86-64 -mtune=generic"

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

RUN dnf -y update && \
    dnf -y install epel-release && \
    dnf -y install \
      gcc gcc-c++ make cmake git pkgconf-pkg-config \
      libftdi-devel libusbx-devel hidapi-devel libgpiod-devel systemd-devel zlib-devel \
      iproute iputils net-tools bind-utils traceroute tcpdump nmap-ncat \
      curl-minimal wget procps-ng psmisc lsof which less vim-minimal findutils tar gzip \
      binutils file && \
    dnf clean all && rm -rf /var/cache/dnf

RUN mkdir -p \
      /opt/spadi/bin \
      /opt/spadi/lib \
      /opt/spadi/lib64 \
      /opt/spadi/include \
      /opt/spadi/share \
      /opt/spadi/etc \
      /opt/spadi/src \
      /opt/spadi/scripts/local \
      /workspace && \
    chmod 1777 /workspace

WORKDIR /opt/spadi/src

RUN git clone https://github.com/spadi-alliance/hul-common-lib.git hul-common-lib && \
    cd hul-common-lib && \
    git checkout "${HUL_COMMON_LIB_REF}" && \
    cmake -S . -B build \
      -DCMAKE_BUILD_TYPE=Release \
      -DCMAKE_INSTALL_PREFIX=/opt/spadi \
      -DCMAKE_C_FLAGS_RELEASE="-O2 -DNDEBUG -march=x86-64 -mtune=generic" \
      -DCMAKE_CXX_FLAGS_RELEASE="-O2 -DNDEBUG -march=x86-64 -mtune=generic" && \
    cmake --build build -j"${NPROC}" && \
    cmake --install build

RUN git clone https://github.com/spadi-alliance/amaneq-soft.git amaneq-soft && \
    cd amaneq-soft && \
    git checkout "${AMANEQ_SOFT_REF}" && \
    cmake -S . -B build \
      -DCMAKE_BUILD_TYPE=Release \
      -DCMAKE_INSTALL_PREFIX=/opt/spadi \
      -DCMAKE_PREFIX_PATH=/opt/spadi \
      -DCMAKE_C_FLAGS_RELEASE="-O2 -DNDEBUG -march=x86-64 -mtune=generic" \
      -DCMAKE_CXX_FLAGS_RELEASE="-O2 -DNDEBUG -march=x86-64 -mtune=generic" && \
    cmake --build build -j"${NPROC}" && \
    cmake --install build

RUN git clone https://github.com/trabucayre/openFPGALoader.git openFPGALoader && \
    cd openFPGALoader && \
    git checkout "${OPENFPGALOADER_REF}" && \
    cmake -S . -B build \
      -DCMAKE_BUILD_TYPE=Release \
      -DCMAKE_INSTALL_PREFIX=/opt/spadi \
      -DCMAKE_C_FLAGS_RELEASE="-O2 -DNDEBUG -march=x86-64 -mtune=generic" \
      -DCMAKE_CXX_FLAGS_RELEASE="-O2 -DNDEBUG -march=x86-64 -mtune=generic" && \
    cmake --build build -j"${NPROC}" && \
    cmake --install build

RUN git clone https://github.com/nobukoba/sitcp-sitcpxg-mpc-mpcx-ip-utility-first-trial.git \
      sitcp-sitcpxg-mpc-mpcx-ip-utility-first-trial && \
    cd sitcp-sitcpxg-mpc-mpcx-ip-utility-first-trial && \
    git checkout "${SITCP_IP_UTILITY_REF}" && \
    make -j"${NPROC}" CXXFLAGS="-O2 -std=c++11 -march=x86-64 -mtune=generic" && \
    make PREFIX=/opt/spadi install

RUN printf '%s\n' '/opt/spadi/lib' '/opt/spadi/lib64' > /etc/ld.so.conf.d/spadi.conf && ldconfig

COPY scripts/smoke-test-fee.sh /opt/spadi/scripts/smoke-test-fee.sh
RUN chmod 0755 /opt/spadi/scripts/smoke-test-fee.sh

WORKDIR /workspace

FROM fee-build AS devel-fee

ENV SPADI_IMAGE_KIND=devel
CMD ["/bin/bash"]

FROM fee-build AS fee-runtime-files

RUN rm -rf /opt/spadi/src && \
    rm -rf /opt/spadi/include && \
    find /opt/spadi -type d -name CMakeFiles -prune -exec rm -rf '{}' + || true

FROM almalinux:9 AS user-fee

ENV SPADI_ROOT=/opt/spadi
ENV SPADI_IMAGE_KIND=user
ENV PATH=/opt/spadi/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
ENV LD_LIBRARY_PATH=/opt/spadi/lib:/opt/spadi/lib64
ENV CMAKE_PREFIX_PATH=/opt/spadi
ENV PKG_CONFIG_PATH=/opt/spadi/lib/pkgconfig:/opt/spadi/lib64/pkgconfig

RUN dnf -y update && \
    dnf -y install epel-release && \
    dnf -y install \
      iproute iputils net-tools bind-utils traceroute tcpdump nmap-ncat \
      curl-minimal wget procps-ng psmisc lsof which less vim-minimal findutils tar gzip \
      libftdi libusbx hidapi libgpiod systemd-libs zlib && \
    dnf clean all && rm -rf /var/cache/dnf

COPY --from=fee-runtime-files /opt/spadi /opt/spadi

RUN mkdir -p /workspace && chmod 1777 /workspace && \
    printf '%s\n' '/opt/spadi/lib' '/opt/spadi/lib64' > /etc/ld.so.conf.d/spadi.conf && \
    ldconfig

WORKDIR /workspace
CMD ["/bin/bash"]

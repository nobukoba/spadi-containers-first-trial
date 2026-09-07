# syntax=docker/dockerfile:1

ARG FEE_DEVEL_IMAGE=ghcr.io/nobukoba/spadi-containers-first-trial/spadi-devel-fee:latest
ARG FEE_USER_IMAGE=ghcr.io/nobukoba/spadi-containers-first-trial/spadi-user-fee:latest

FROM ${FEE_DEVEL_IMAGE} AS daq-build

ARG NPROC=4
ARG LIBZMQ_VERSION=v4.3.5
ARG FMT_VERSION=10.2.1
ARG FAIRMQ_VERSION=v1.4.55
ARG HIREDIS_VERSION=v1.1.0
ARG REDIS_PLUS_PLUS_VERSION=1.3.6
ARG REDISTIMESERIES_VERSION=v1.10.24

ENV SPADI_ROOT=/opt/spadi
ENV EXP_CONFIG_ROOT=/opt/spadi/scripts/exp-config
ENV PATH=/opt/spadi/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
ENV LD_LIBRARY_PATH=/opt/spadi/lib:/opt/spadi/lib64
ENV CMAKE_PREFIX_PATH=/opt/spadi
ENV PKG_CONFIG_PATH=/opt/spadi/lib/pkgconfig:/opt/spadi/lib64/pkgconfig
ENV CFLAGS="-O2 -march=x86-64 -mtune=generic -mno-avx -mno-avx2"
ENV CXXFLAGS="-O2 -march=x86-64 -mtune=generic -mno-avx -mno-avx2"

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

RUN dnf -y install \
      boost-devel openssl-devel libuuid-devel sqlite-devel \
      bzip2-devel xz-devel zlib-devel libzstd-devel \
      libtool autoconf automake python3 python3-pip python3-setuptools \
      rsync jq valkey tmux xterm binutils file diffutils patch && \
    dnf clean all && rm -rf /var/cache/dnf

RUN mkdir -p \
      /opt/spadi/src \
      /opt/spadi/scripts/local \
      /workspace && \
    chmod 1777 /workspace

RUN cd /opt/spadi/src && \
    git clone --depth 1 --branch ${LIBZMQ_VERSION} https://github.com/zeromq/libzmq.git && \
    cmake -S libzmq -B libzmq/build \
      -DCMAKE_BUILD_TYPE=Release \
      -DCMAKE_INSTALL_PREFIX=/opt/spadi \
      -DCMAKE_INSTALL_LIBDIR=lib \
      -DCMAKE_POSITION_INDEPENDENT_CODE=ON \
      -DBUILD_TESTS=OFF -DENABLE_DRAFTS=OFF && \
    cmake --build libzmq/build -j${NPROC} && \
    cmake --install libzmq/build

RUN cd /opt/spadi/src && \
    git clone --depth 1 --branch ${FMT_VERSION} https://github.com/fmtlib/fmt.git && \
    cmake -S fmt -B fmt/build \
      -DCMAKE_BUILD_TYPE=Release \
      -DCMAKE_INSTALL_PREFIX=/opt/spadi \
      -DCMAKE_INSTALL_LIBDIR=lib \
      -DCMAKE_POSITION_INDEPENDENT_CODE=ON \
      -DBUILD_SHARED_LIBS=ON -DFMT_TEST=OFF -DFMT_DOC=OFF && \
    cmake --build fmt/build -j${NPROC} && \
    cmake --install fmt/build

RUN cd /opt/spadi/src && \
    git clone --depth 1 https://github.com/FairRootGroup/FairLogger.git && \
    cmake -S FairLogger -B FairLogger/build \
      -DCMAKE_BUILD_TYPE=Release \
      -DCMAKE_INSTALL_PREFIX=/opt/spadi \
      -DCMAKE_INSTALL_LIBDIR=lib \
      -DCMAKE_PREFIX_PATH=/opt/spadi \
      -DCMAKE_POSITION_INDEPENDENT_CODE=ON \
      -DCMAKE_CXX_STANDARD=17 \
      -DUSE_EXTERNAL_FMT=ON && \
    cmake --build FairLogger/build -j${NPROC} && \
    cmake --install FairLogger/build

RUN cd /opt/spadi/src && \
    git clone --depth 1 --branch ${FAIRMQ_VERSION} https://github.com/FairRootGroup/FairMQ.git && \
    cmake -S FairMQ -B FairMQ/build \
      -DCMAKE_BUILD_TYPE=Release \
      -DCMAKE_INSTALL_PREFIX=/opt/spadi \
      -DCMAKE_INSTALL_LIBDIR=lib \
      -DCMAKE_PREFIX_PATH=/opt/spadi \
      -DCMAKE_POSITION_INDEPENDENT_CODE=ON \
      -DCMAKE_CXX_STANDARD=17 \
      -DBUILD_TESTING=OFF && \
    cmake --build FairMQ/build -j${NPROC} && \
    cmake --install FairMQ/build

RUN cd /opt/spadi/src && \
    git clone --depth 1 --branch ${HIREDIS_VERSION} https://github.com/redis/hiredis.git && \
    make -C hiredis -j${NPROC} PREFIX=/opt/spadi LIBRARY_PATH=lib && \
    make -C hiredis PREFIX=/opt/spadi LIBRARY_PATH=lib install

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

# NestDAQ metrics uses RedisTimeSeries commands such as TS.ADD.
RUN cd /opt/spadi/src && \
    git clone --recursive --depth 1 --branch ${REDISTIMESERIES_VERSION} \
      https://github.com/RedisTimeSeries/RedisTimeSeries.git && \
    cd RedisTimeSeries && \
    make -j${NPROC} build DEPS=1 && \
    RTS_SO="$(find bin -type f -name redistimeseries.so -print -quit)" && \
    test -n "${RTS_SO}" && \
    install -m 0755 "${RTS_SO}" /opt/spadi/lib/redistimeseries.so

# Upstream NestDAQ currently uses -march=native in Release builds. Replace it
# at the source so GitHub runner CPU features cannot leak into distributed
# binaries. Keep the baseline usable on generic x86-64 machines without AVX.
RUN cd /opt/spadi/src && \
    git clone --depth 1 https://github.com/spadi-alliance/nestdaq.git && \
    sed -i \
      's/-Ofast -DNDEBUG -march=native/-Ofast -DNDEBUG -march=x86-64 -mtune=generic -mno-avx -mno-avx2/' \
      nestdaq/cmake/common.cmake && \
    sed -i 's/ec\.what()/ec.message()/g' \
      nestdaq/controller/websocket_session.cxx \
      nestdaq/controller/http_session.cxx \
      nestdaq/controller/HttpWebSocketServer.cxx && \
    ! grep -R --line-number -- '-march=native' nestdaq/cmake nestdaq/CMakeLists.txt && \
    cmake -S nestdaq -B nestdaq/build \
      -DCMAKE_BUILD_TYPE=Release \
      -DCMAKE_INSTALL_PREFIX=/opt/spadi \
      -DCMAKE_INSTALL_LIBDIR=lib \
      -DCMAKE_PREFIX_PATH=/opt/spadi \
      -DCMAKE_POSITION_INDEPENDENT_CODE=ON \
      -DCMAKE_CXX_STANDARD=17 && \
    cmake --build nestdaq/build -j${NPROC} --verbose && \
    cmake --install nestdaq/build

RUN cd /opt/spadi/src && \
    git clone --depth 1 https://github.com/spadi-alliance/uhbook.git && \
    ln -sf /opt/spadi/src/uhbook/uhbook.cxx /opt/spadi/include/uhbook.cxx

# nestdaq-user-impl also sets -march=native for Release builds. The project
# currently declares several internal libraries after executables that link to
# them; move those subdirectories before the executable definitions as in the
# proven reference container. ROOT-dependent TriggerView is disabled in DAQ-only
# images; it is available later in the FULL image where ROOT is present.
RUN cd /opt/spadi/src && \
    git clone --depth 1 https://github.com/spadi-alliance/nestdaq-user-impl.git && \
    python3 - <<'PY'
from pathlib import Path
p = Path('/opt/spadi/src/nestdaq-user-impl/CMakeLists.txt')
s = p.read_text()
s = s.replace('find_package(ROOT REQUIRED COMPONENTS RIO RHTTP Hist)',
              'message(STATUS "ROOT support disabled in DAQ-only image")')
s = s.replace('    TriggerView;\n', '')
s = s.replace('set(CMAKE_CXX_FLAGS_RELEASE "-Ofast -DNDEBUG -march=native")',
              'set(CMAKE_CXX_FLAGS_RELEASE "-Ofast -DNDEBUG -march=x86-64 -mtune=generic -mno-avx -mno-avx2 -fpermissive")')
s = s.replace('  target_include_directories(${EXEC} PUBLIC \n',
              '  target_include_directories(${EXEC} PUBLIC \n    ${CMAKE_INSTALL_PREFIX}/include;\n', 1)
s = s.replace('#==============================================================================\n# Sampler(for Emulator), Sink, FileSink, STFBuilder, TimeFrameBuilder\n',
              '#==============================================================================\n# Internal libraries must exist before executables link to them.\nadd_subdirectory(utility)\nadd_subdirectory(emulator)\nadd_subdirectory(sqlite)\n\n#==============================================================================\n# Sampler(for Emulator), Sink, FileSink, STFBuilder, TimeFrameBuilder\n', 1)
s = s.replace('#================================================================================\nadd_subdirectory(utility)\nadd_subdirectory(emulator)\nadd_subdirectory(sqlite)\n', '', 1)
p.write_text(s)
PY

RUN ! grep -R --line-number -- '-march=native' /opt/spadi/src/nestdaq-user-impl/CMakeLists.txt && \
    cmake -S /opt/spadi/src/nestdaq-user-impl \
      -B /opt/spadi/src/nestdaq-user-impl/build \
      -DCMAKE_BUILD_TYPE=Release \
      -DCMAKE_INSTALL_PREFIX=/opt/spadi \
      -DCMAKE_INSTALL_LIBDIR=lib \
      -DCMAKE_PREFIX_PATH="/opt/spadi;/opt/spadi/src/uhbook" \
      -DCMAKE_POSITION_INDEPENDENT_CODE=ON \
      -DCMAKE_CXX_STANDARD=17 && \
    cmake --build /opt/spadi/src/nestdaq-user-impl/build -j${NPROC} --verbose && \
    cmake --install /opt/spadi/src/nestdaq-user-impl/build

RUN git clone --depth 1 https://github.com/spadi-alliance/exp-config.git /opt/spadi/scripts/exp-config

# Fail the build if representative distributed binaries contain AVX register
# use. This catches accidental reintroduction of native CPU tuning.
RUN for exe in /opt/spadi/bin/daq-webctl /opt/spadi/bin/TimeFrameBuilder /opt/spadi/bin/STFBFilePlayer; do \
      test -x "$exe"; \
      objdump -d "$exe" > /tmp/spadi.dis; \
      if grep -Eq 'vzeroupper|ymm[0-9]+|zmm[0-9]+|vmovdqu' /tmp/spadi.dis; then \
        echo "ERROR: AVX instructions found in $exe" >&2; \
        exit 1; \
      fi; \
    done && rm -f /tmp/spadi.dis

RUN printf '%s\n' '/opt/spadi/lib' '/opt/spadi/lib64' > /etc/ld.so.conf.d/spadi.conf && ldconfig

COPY scripts/smoke-test-daq.sh /opt/spadi/scripts/smoke-test-daq.sh
RUN chmod 0755 /opt/spadi/scripts/smoke-test-daq.sh

WORKDIR /workspace

FROM daq-build AS devel-daq
ENV SPADI_IMAGE_KIND=devel
CMD ["/bin/bash"]

FROM daq-build AS daq-runtime-files
RUN rm -rf /opt/spadi/src && rm -rf /opt/spadi/include

FROM ${FEE_USER_IMAGE} AS user-daq

ENV SPADI_ROOT=/opt/spadi
ENV SPADI_IMAGE_KIND=user
ENV EXP_CONFIG_ROOT=/opt/spadi/scripts/exp-config
ENV PATH=/opt/spadi/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
ENV LD_LIBRARY_PATH=/opt/spadi/lib:/opt/spadi/lib64
ENV CMAKE_PREFIX_PATH=/opt/spadi
ENV PKG_CONFIG_PATH=/opt/spadi/lib/pkgconfig:/opt/spadi/lib64/pkgconfig

RUN dnf -y install \
      boost openssl-libs libuuid sqlite-libs bzip2-libs xz-libs zlib libzstd \
      valkey tmux && \
    dnf clean all && rm -rf /var/cache/dnf

COPY --from=daq-runtime-files /opt/spadi /opt/spadi

RUN mkdir -p /workspace && chmod 1777 /workspace && \
    printf '%s\n' '/opt/spadi/lib' '/opt/spadi/lib64' > /etc/ld.so.conf.d/spadi.conf && \
    ldconfig

WORKDIR /workspace
CMD ["/bin/bash"]

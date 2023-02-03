################################################################################
# - (from the PROJECT_SOURCE_DIR)
# - podman build -f tests/deb/0_build.dockerfile -t abc_build:dev --volume $(pwd):/home/root/abc:ro .
# - CHECK: inspect the .deb:
#   - docker cp $(docker create --name my_abc_dev abc_build:dev):/home/root/abc.deb ./abc.deb && docker rm my_abc_dev
#   - dpkg -I abc.deb

# TO MATCH CI and Rust base image:
# - SHOULD use a ubuntu for the "builder" part
# - SHOULD use a debian part for the final image
#
# That way we SHOULD be able to catch eg
#   The following packages have unmet dependencies:
#   abc : Depends: libstdc++6 (>= 11) but 10.2.1-6 is to be installed
FROM debian:latest

WORKDIR /home/root/

# - DEBIAN_FRONTEND needed to stop prompt for timezone
# - MUST install make: the Makefile is pretty much hardcoded to use make for "extract_var" etc
#   CMake Error at CMakeLists.txt:99 (extract_var):
#       extract_var Function invoked with incorrect arguments for function named:
#       extract_var
# - file: CMake Error at /opt/cmake/share/cmake-3.22/Modules/Internal/CPack/CPackDeb.cmake:165 (message):
#       CPackDeb: file utility is not available.  CPACK_DEBIAN_PACKAGE_SHLIBDEPS
#       and CPACK_DEBIAN_PACKAGE_GENERATE_SHLIBS options are not available
# - dpkg-dev: "CPackDeb: Using only user-provided dependencies because dpkg-shlibdeps is not found." and the final .deb has no deps
#       Which means at runtime we get "/usr/bin/abc: error while loading shared libraries: libreadline.so.8: cannot open shared object file: No such file or directory"
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y \
    wget unzip xz-utils lsb-release software-properties-common gnupg make libreadline-dev file dpkg-dev \
    && rm -rf /var/lib/apt/lists/*

# prereq: install CMake
ENV PATH=$PATH:/opt/cmake/bin/
RUN export MY_CMAKE_VERSION=3.25.1 && \
    wget https://github.com/Kitware/CMake/releases/download/v$MY_CMAKE_VERSION/cmake-$MY_CMAKE_VERSION-linux-x86_64.sh && \
    chmod +x cmake-$MY_CMAKE_VERSION-linux-x86_64.sh && \
    mkdir /opt/cmake/ && \
    ./cmake-$MY_CMAKE_VERSION-linux-x86_64.sh --skip-license --prefix=/opt/cmake/ && \
    rm cmake-*.sh && \
    cmake -version

# prereq: install Ninja (ninja-build)
RUN wget https://github.com/ninja-build/ninja/releases/download/v1.10.2/ninja-linux.zip && \
    unzip ninja-linux.zip -d /usr/local/bin/ && \
    rm ninja-linux.zip && \
    ninja --version

# prereq: install clang
# https://baykara.medium.com/installing-clang-10-in-a-docker-container-4c24a4538af2
# ENV LLVM_VERSION clang+llvm-13.0.1-x86_64-linux-gnu-ubuntu-18.04
# RUN wget https://github.com/llvm/llvm-project/releases/download/llvmorg-13.0.1/$LLVM_VERSION.tar.xz && \
#     mkdir -p /opt/$LLVM_VERSION && \
#     tar -xf $LLVM_VERSION.tar.xz -C /opt/$LLVM_VERSION && \
#     mkdir -p /opt/llvm && \
#     mv /opt/$LLVM_VERSION/$LLVM_VERSION/* /opt/llvm && \
#     rm $LLVM_VERSION.tar.xz
# cf https://apt.llvm.org/
#
# RUN wget https://apt.llvm.org/llvm.sh && \
#     chmod +x llvm.sh && \
#     export MY_LVVM_VERSION=15 && \
#     ./llvm.sh $MY_LVVM_VERSION && \
#     rm -rf /var/lib/apt/lists/* && \
#     update-alternatives --install /usr/bin/clang clang /usr/bin/clang-$MY_LVVM_VERSION 100 && \
#     update-alternatives --install /usr/bin/clang++ clang++ /usr/bin/clang++-$MY_LVVM_VERSION 100 && \
#     rm ./llvm.sh && \
#     clang --version
#
RUN apt-get update && apt-get install -y \
    g++ \
    && rm -rf /var/lib/apt/lists/* && \
    g++ --version

# NOTE:
# - the source files are under /home/root/abc; which SHOULD be a read-only volume
# - we build under /home/root/build
RUN mkdir -p build && \
    cd build && \
    cmake -GNinja -DCMAKE_BUILD_TYPE=Release ../abc && \
    cmake --build . && \
    cpack && echo && \
    ls -al *.deb && \
    mv /home/root/build/interstellar-abc-0.1.1-Linux.deb /home/root/abc.deb

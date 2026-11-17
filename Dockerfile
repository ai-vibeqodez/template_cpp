# syntax=docker/dockerfile:1.7
#
# CI image for C++20 projects (tpl / tobus).
# Pushed to ghcr.io/ai-warevo/ci-cpp20 on tag.
#
# Toolchains:
#   gcc-15 (libstdc++) — default gcc/g++
#   clang-18 (libc++)   — clang++-18 -stdlib=libc++
#   clang-18 (libstdc++) — clang++-18, default stdlib
# Bundled: cmake, ninja, clang-format, clang-tidy, gcovr, ASan/TSan runtimes
#
# Usage in GitHub Actions:
#   runs-on: ubuntu-latest
#   container: ghcr.io/ai-warevo/ci-cpp20:<tag>
#   (no setup-toolchain action needed)

ARG BASE_IMAGE=docker.io/runzhliu/deepseek-harness:0.2.2-rc.3-r1
FROM ${BASE_IMAGE}

USER root

RUN echo 'deb https://deb.debian.org/debian forky main' > /etc/apt/sources.list.d/forky.list && \
    printf 'Package: *\nPin: release n=forky\nPin-Priority: 100\n' > /etc/apt/preferences.d/forky && \
    apt-get update && \
    apt-get install -y --no-install-recommends \
        build-essential \
        ca-certificates \
        clang-18 \
        libc++-18-dev \
        libc++abi-18-dev \
        libunwind-18-dev \
        libclang-rt-18-dev \
        cmake \
        gdb \
        git \
        lld \
        ninja-build \
    && \
    apt-get install -y --no-install-recommends -t forky gcc-15 g++-15 gcovr && \
    rm -rf /var/lib/apt/lists/* && \
    ln -sf /usr/bin/gcc-15 /usr/bin/gcc && \
    ln -sf /usr/bin/g++-15 /usr/bin/g++ && \
    g++-15 --version

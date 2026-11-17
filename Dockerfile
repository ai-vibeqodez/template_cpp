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

FROM debian:trixie

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        build-essential \
        ca-certificates \
        clang \
        clang-18 \
        clang-format-18 \
        clang-tidy-18 \
        cmake \
        gdb \
        git \
        lld \
        libc++-18-dev \
        libc++abi-18-dev \
        libunwind-18-dev \
        libclang-rt-18-dev \
        ninja-build \
        gcc-15 \
        g++-15 \
        gcovr \
    && \
    rm -rf /var/lib/apt/lists/* && \
    ln -sf /usr/bin/gcc-15 /usr/bin/gcc && \
    ln -sf /usr/bin/g++-15 /usr/bin/g++ && \
    g++-15 --version && \
    clang++-18 --version

# syntax=docker/dockerfile:1.7
#
# CI image for C++20 projects (tpl / tobus).
# Pushed to ghcr.io/ai-warevo/ci-cpp20 on tag.
#
# Toolchains:
#   gcc-15 (libstdc++) — default gcc/g++
#   clang-18 (libc++)   — clang++-18 -stdlib=libc++
#   clang-18 (libstdc++) — clang++-18, default stdlib
# Bundled: cmake, ninja, clang-format-18, clang-tidy-18, gcovr, ASan/TSan runtimes
#
# Usage in GitHub Actions:
#   runs-on: ubuntu-24.04
#   container: ghcr.io/ai-warevo/ci-cpp20:<tag>
#   (no setup-toolchain action needed)

FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive
ENV LANG=C.UTF-8

# ── Debian forky repo (gcc-15, gcovr) ────────────────────────────────
RUN echo 'deb https://deb.debian.org/debian forky main' > /etc/apt/sources.list.d/forky.list

# ── All packages (Ubuntu 24.04 + forky) ──────────────────────────────
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        build-essential \
        ca-certificates \
        git \
        cmake \
        ninja-build \
        lld \
        gdb \
        clang-18 \
        clang-format-18 \
        clang-tidy-18 \
        libc++-18-dev \
        libc++abi-18-dev \
        libunwind-18-dev \
        libclang-rt-18-dev \
        gcc-15 \
        g++-15 \
        gcovr \
    && \
    rm -rf /var/lib/apt/lists/*

# ── Symlinks: clang tools + gcc-15 as default ────────────────────────
# clang-format / clang-tidy actions call them without version suffix.
# gcc-15 as default so gcovr finds matching gcov-15.
RUN ln -sf /usr/bin/clang-format-18 /usr/local/bin/clang-format && \
    ln -sf /usr/bin/clang-tidy-18 /usr/local/bin/clang-tidy && \
    ln -sf /usr/bin/gcc-15 /usr/bin/gcc && \
    ln -sf /usr/bin/g++-15 /usr/bin/g++

# ── Version stamp ────────────────────────────────────────────────────
ARG BUILD_DATE
ARG GIT_VERSION
LABEL org.opencontainers.image.created="${BUILD_DATE}" \
      org.opencontainers.image.version="${GIT_VERSION}" \
      org.opencontainers.image.source="https://github.com/ai-warevo/template-cpp"

# syntax=docker/dockerfile:1.7
#
# CI image for C++20 projects (tpl / tobus).
# Pushed to ghcr.io/ai-warevo/ci-cpp20 on tag.
#
# Toolchains:
#   gcc-15 (libstdc++) — default gcc/g++ (from Debian forky/unstable)
#   clang-18 (libc++)   — clang++-18 -stdlib=libc++ (from Debian trixie)
#   clang-18 (libstdc++) — clang++-18, default stdlib (from Debian trixie)
# Linters:
#   clang-tidy-18 (from Debian trixie)
#   clang-format-18 (>= 15, from Debian trixie)
# Bundled: cmake, ninja-build, gcovr (forky), gdb, lld, ASan/TSan runtimes
#
# Usage in GitHub Actions:
#   runs-on: ubuntu-latest
#   container: ghcr.io/ai-warevo/ci-cpp20:<tag>
#   (no setup-toolchain action needed)

FROM debian:trixie

ENV DEBIAN_FRONTEND=noninteractive

# Add forky (unstable) repo with low priority so it doesn't override trixie packages.
RUN echo 'deb https://deb.debian.org/debian forky main' > /etc/apt/sources.list.d/forky.list && \
    printf 'Package: *\nPin: release n=forky\nPin-Priority: 100\n' > /etc/apt/preferences.d/forky && \
    apt-get update && \
    # Main packages from trixie
    apt-get install -y --no-install-recommends \
        build-essential \
        ca-certificates \
        clang-18 \
        clang-format-18 \
        clang-tidy-18 \
        cmake \
        gdb \
        git \
        lld-18 \
        libc++-18-dev \
        libc++abi-18-dev \
        libunwind-18-dev \
        libclang-rt-18-dev \
        ninja-build \
    && \
    # gcc-15 and matching gcovr from forky (unstable)
    apt-get install -y --no-install-recommends -t forky \
        gcc-15 \
        g++-15 \
        gcovr \
    && \
    rm -rf /var/lib/apt/lists/* && \
    ln -sf /usr/bin/gcc-15 /usr/bin/gcc && \
    ln -sf /usr/bin/g++-15 /usr/bin/g++ && \
    ln -sf /usr/bin/clang-tidy-18 /usr/bin/clang-tidy && \
    ln -sf /usr/bin/clang-format-18 /usr/bin/clang-format && \
    g++-15 --version && \
    clang++-18 --version

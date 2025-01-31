#
# Dockerfile - Build a custom OpenWRT firmware image.
#


# SHA256 from: docker inspect --format='{{index .RepoDigests 0}}' debian:bookworm-slim
ARG DEBIAN_BASE_IMAGE="debian@sha256:f70dc8d6a8b6a06824c92471a1a258030836b26b043881358b967bf73de7c5ab"


FROM $DEBIAN_BASE_IMAGE

ARG BUILD_ROOT="/var/openwrt-build"
ARG BUILD_USER="openwrt"
ARG BUILD_USER_ID=1143
ARG BUILD_TAG="custom"

ARG OPENWRT_TARGET
ARG OPENWRT_SUBTARGET
ARG OPENWRT_PROFILE
ARG OPENWRT_RELEASE

SHELL ["/bin/bash", "-exo", "pipefail", "-c"]

# The OpenWRT image builder terminates with a segmentation fault under Rosetta, but works fine under QEMU.
# I'm not aware of any CLI parameter to force the use of QEMU. The only option seems to be through the GUI.
RUN if grep -q '[r]osetta' /proc/[1-9]*/cmdline; then \
        echo -ne '\n##' \
                 '\n## The OpenWRT image builder does not work properly under Apple Rosetta x86-64 emulation.' \
                 '\n##' \
                 '\n## Please (temporarily) uncheck "Use Rosetta for x86_64/amd64 emulation on Apple Silicon"' \
                 '\n## in the Docker Desktop "General / Virtual Machine Options" section to use QEMU instead.' \
                 '\n##\n\n' >&2; \
        exit 1; \
    fi

RUN useradd -m -d "$BUILD_ROOT" -s /bin/false -U "$BUILD_USER" -u "$BUILD_USER_ID"

RUN apt-get -qq -y update \
    && apt-get -q -y install --no-install-recommends --no-install-suggests \
        ca-certificates \
        curl \
        xz-utils \
        build-essential \
        gawk \
        unzip \
        wget \
        python3 \
        python3-distutils \
        git \
        file \
        rsync \
    && apt-get -qq -y clean all \
    && rm -rf /var/lib/apt/lists/*

USER $BUILD_USER_ID
WORKDIR $BUILD_ROOT

RUN curl -sSL "https://downloads.openwrt.org/releases/${OPENWRT_RELEASE}/targets/${OPENWRT_TARGET}/${OPENWRT_SUBTARGET}/openwrt-imagebuilder-${OPENWRT_RELEASE}-${OPENWRT_TARGET}-${OPENWRT_SUBTARGET}.Linux-x86_64.tar.xz" \
        | tar --strip-components=1 -Jxf -

# This allows the Makefile to bust the layer cache to get updated packages...
RUN echo "Building..."  # __CACHE_BUSTER__

COPY --chown=$BUILD_USER_ID:$BUILD_USER_ID custom-packages.txt disabled-services.txt "${BUILD_ROOT}/"

#
# Some packages embed a version in their names which changes when they break binary compatibility.
# To avoid sticking with stale versions of those packages, and other packages that depend upon them,
# they must be excluded from the list so they're pulled in (automatically) as dependencies instead.
#
RUN UPSTREAM_MANIFEST="${PWD}/openwrt-${OPENWRT_RELEASE}-${OPENWRT_TARGET}-${OPENWRT_SUBTARGET}-${OPENWRT_PROFILE}.manifest" \
    && CUSTOM_MANIFEST="${PWD}/bin/targets/${OPENWRT_TARGET}/${OPENWRT_SUBTARGET}/openwrt-${OPENWRT_RELEASE}-${BUILD_TAG}-${OPENWRT_TARGET}-${OPENWRT_SUBTARGET}-${OPENWRT_PROFILE}.manifest" \
    && curl -o "$UPSTREAM_MANIFEST" -sSL "https://downloads.openwrt.org/releases/${OPENWRT_RELEASE}/targets/${OPENWRT_TARGET}/${OPENWRT_SUBTARGET}/openwrt-${OPENWRT_RELEASE}-${OPENWRT_TARGET}-${OPENWRT_SUBTARGET}.manifest" \
    && awk '{print $1}' "$UPSTREAM_MANIFEST" | grep -vP '^lib(wolfssl|usb|.+[^0-9]20[0-9]{2}[01][0-9][0-3][0-9]$)' > default-packages.txt \
    && make image PROFILE="$OPENWRT_PROFILE" \
                  PACKAGES="$(cat default-packages.txt custom-packages.txt | sed 's/#.*//g; s/ *//g' | sort -u | xargs)" \
                  DISABLED_SERVICES="$(cat disabled-services.txt | sed 's/#.*//' | xargs)" \
                  EXTRA_IMAGE_NAME="$BUILD_TAG" \
    && diff -u "$UPSTREAM_MANIFEST" "$CUSTOM_MANIFEST" > "${CUSTOM_MANIFEST}.diff" || true


# EOF - Dockerfile

#
# Dockerfile - Build a custom OpenWRT firmware image.
#


# SHA256 from: docker inspect --format='{{index .RepoDigests 0}}' debian:bullseye-slim
ARG DEBIAN_BASE_IMAGE="debian@sha256:b46fc4e6813f6cbd9f3f6322c72ab974cc0e75a72ca02730a8861e98999875c7"


FROM $DEBIAN_BASE_IMAGE

ARG BUILD_ROOT="/var/openwrt-build"
ARG BUILD_USER="openwrt"
ARG BUILD_USER_ID=1143

ARG OPENWRT_TARGET
ARG OPENWRT_SUBTARGET
ARG OPENWRT_PROFILE
ARG OPENWRT_RELEASE

SHELL ["/bin/bash", "-exo", "pipefail", "-c"]

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
RUN curl -sSL "https://downloads.openwrt.org/releases/${OPENWRT_RELEASE}/targets/${OPENWRT_TARGET}/${OPENWRT_SUBTARGET}/openwrt-${OPENWRT_RELEASE}-${OPENWRT_TARGET}-${OPENWRT_SUBTARGET}.manifest" \
        | awk '{print $1}' | grep -v '^libwolfssl' > default-packages.txt \
    && make image PROFILE="$OPENWRT_PROFILE" \
               PACKAGES="$(cat default-packages.txt custom-packages.txt | sed 's/#.*//g; s/ *//g' | sort -u | xargs)" \
               DISABLED_SERVICES="$(cat disabled-services.txt | sed 's/#.*//' | xargs)" \
               EXTRA_IMAGE_NAME="custom"


# EOF - Dockerfile

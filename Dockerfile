#
# Dockerfile - Build a custom OpenWRT firmware image.
#


# SHA256 from: docker inspect --format='{{index .RepoDigests 0}}' debian:bullseye-slim
ARG DEBIAN_BASE_IMAGE="debian@sha256:f75d8a3ac10acdaa9be6052ea5f28bcfa56015ff02298831994bd3e6d66f7e57"


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
        | tar --strip-components=1 -Jxf - \
    && curl -sSL "https://downloads.openwrt.org/releases/${OPENWRT_RELEASE}/targets/${OPENWRT_TARGET}/${OPENWRT_SUBTARGET}/openwrt-${OPENWRT_RELEASE}-${OPENWRT_TARGET}-${OPENWRT_SUBTARGET}.manifest" \
        | awk '{print $1}' > default-packages.txt

COPY --chown=$BUILD_USER_ID:$BUILD_USER_ID custom-packages.txt disabled-services.txt "${BUILD_ROOT}/"

RUN make image PROFILE="$OPENWRT_PROFILE" \
               PACKAGES="$(cat default-packages.txt custom-packages.txt | sed 's/#.*//g; s/ *//g' | sort -u | xargs)" \
               DISABLED_SERVICES="$(cat disabled-services.txt | sed 's/#.*//' | xargs)" \
               EXTRA_IMAGE_NAME="custom"


# EOF - Dockerfile
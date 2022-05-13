#
# GNU Makefile
#


SHELL := bash -e

OPENWRT_RELEASE := 21.02.3

OPENWRT_TARGET := mvebu
OPENWRT_SUBTARGET := cortexa9
OPENWRT_PROFILE := linksys_wrt1900acs

DOCKER_IMAGE := openwrt-custom-builder:$(OPENWRT_RELEASE)


.PHONY: all
all: build

.PHONY: build
build:
	docker build -t $(DOCKER_IMAGE) -f Dockerfile \
	       --build-arg OPENWRT_TARGET=$(OPENWRT_TARGET) \
	       --build-arg OPENWRT_SUBTARGET=$(OPENWRT_SUBTARGET) \
	       --build-arg OPENWRT_PROFILE=$(OPENWRT_PROFILE) \
	       --build-arg OPENWRT_RELEASE=$(OPENWRT_RELEASE) \
	       .
	mkdir -p firmware
	docker run $(DOCKER_IMAGE) tar -c -C "bin/targets/$(OPENWRT_TARGET)/$(OPENWRT_SUBTARGET)" . | tar x -C firmware

.PHONY: clean
clean:
	rm -rf firmware


# EOF - Makefile
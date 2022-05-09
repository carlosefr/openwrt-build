# Custom OpenWRT Firmware

Easily build a custom OpenWRT firmware image with extra packages.

## Instructions

First, make sure you have `docker` and `make` installed.

Then, lookup your device in the [table of hardware](https://openwrt.org/toh/views/toh_fwdownload?dataflt%5B0%5D=supported%20current%20rel_%3D21.02.3) and modify the following variables in the `Makefile` appropriately:

```
OPENWRT_RELEASE := 21.02.3
OPENWRT_TARGET := mvebu
OPENWRT_SUBTARGET := cortexa9
OPENWRT_PROFILE := linksys_wrt1900acs
```

Finally, modify the `custom-packages.txt` and `disabled-services.txt` file to your liking and run:

```
make
```

For more see the [image builder documentation](https://openwrt.org/docs/guide-user/additional-software/imagebuilder).

# OpenWRT Firmware Builder in Docker

Quickly build a custom OpenWRT firmware image with extra packages inside a docker container.

## Instructions

Make sure you have `docker` and `make` installed on your machine, and then edit the `Makefile` with your favorite text editor.

Choose the desired OpenWRT release by modifying the `OPENWRT_RELEASE` variable:
```
OPENWRT_RELEASE := 23.05.5
```

**Note:** The installed package versions will come from this release's repositories but are not locked, meaning some packages in your custom-built image may be newer than those in the pre-built images.

Lookup your device in the [table of hardware](https://openwrt.org/toh/views/toh_fwdownload?dataflt%5B0%5D=supported%20current%20rel_%3D23.05.5) and modify the following variables appropriately:

```
OPENWRT_TARGET := mvebu
OPENWRT_SUBTARGET := cortexa9
OPENWRT_PROFILE := linksys_wrt1900acs
```

Finally, edit the `custom-packages.txt` and `disabled-services.txt` files to your liking and run:

```
make
```

Your custom firmware image should appear in the `firmware` directory within a minute or two.

For more see the [image builder documentation](https://openwrt.org/docs/guide-user/additional-software/imagebuilder).

# Install TWRP — Samsung Galaxy S22 SM-S901B (r0s)

Use **`S901B_twrp_vbmeta_only.tar`** from this folder. This is the previously used FYI3 recovery package, containing `recovery.img` and `vbmeta.img` (no `up_param.bin`).

**Before flashing:** Only for **SM-S901B (Exynos)** with an **unlocked bootloader**. Back up important data. Flashing a modified recovery/vbmeta can affect verified boot, and data may need formatting. Do not use this package on other Galaxy S22 models.

## Flash using Odin

1. Boot the phone into **Download Mode**, then connect it by USB.
2. In **Windows Odin**, select `S901B_twrp_vbmeta_only.tar` in **AP**. Leave BL, CP, CSC and USERDATA empty. Do not select any additional firmware package.
3. Start flashing. As soon as flashing completes, boot **directly into TWRP** instead of allowing a normal Android boot.

On Linux, the previously used equivalent was **Odin4**, passing the TAR as AP (`-a`) and the detected device as `-d`:

```bash
odin4 -a S901B_twrp_vbmeta_only.tar -d "<detected-device>"
```

## Boot directly into recovery

Keep USB connected. During the reboot, hold **Volume Up + Side/Power**; when the Samsung logo appears, release Side/Power but continue holding Volume Up until TWRP loads.

If still in Download Mode: hold **Volume Down + Side/Power** until the screen turns black, then immediately switch to **Volume Up + Side/Power**. Release Side/Power at the Samsung logo and keep Volume Up held.

This archive contains **TWRP recovery and vbmeta only**. It is not a full TachyonOS ROM, and installing it does not install the ROM or kernel.

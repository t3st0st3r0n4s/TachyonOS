# SM-S901B FYI3 — TWRP recovery archive

## Retained file

Retain **one** recovery artifact in GitHub, as a release asset:

`out/device_preflight/twrp_ready/S901B_twrp_vbmeta_only.tar`

This is the existing ready-to-flash TWRP Odin TAR from the S901B FYI3 host preparation. It contains `recovery.img` and `vbmeta.img` and deliberately omits `up_param.bin`.

The `twrp_candidate/` and `twrp_r0s/extracted/` directories contain alternative extracted copies of the same material. **Do not archive them**, the original `S901B_twrp_logo_vbmeta.tar`, or any additional generated packages. The working recovery has already been used on the device; preservation does not require a new runtime qualification or recompilation.

## Original provenance

The prepared TAR originated from the `S901B_twrp_logo_vbmeta.tar` recovery archive associated with [this 4PDA post](https://4pda.to/forum/index.php?showtopic=1043829&view=findpost&p=126991291). The original included `up_param.bin` in addition to the two retained images.

This is a **prebuilt recovery**, not a buildable TWRP source-code checkout. The original TWRP source tree is not claimed to be present in this repository.

## Publication

Publish the **existing TAR only** as a GitHub Release asset in `t3st0st3r0n4s/TachyonOS`, keeping it out of Git source history. No other host artifacts or checksums need to be uploaded. The release upload is a separate action; this documentation commit does not upload the binary.

**Never publish** the EFS backup, stock partition extracts, `s901b_pre_fyi3_state.txt`, or the entire `out/device_preflight/` directory.

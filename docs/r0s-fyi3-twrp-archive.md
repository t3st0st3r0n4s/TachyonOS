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

**Published:** [TWRP S901B FYI3](https://github.com/t3st0st3r0n4s/TachyonOS/releases/tag/twrp-r0s-fyi3) on 2026-10-10, with exactly one GitHub Release asset:

- [S901B_twrp_vbmeta_only.tar](https://github.com/t3st0st3r0n4s/TachyonOS/releases/download/twrp-r0s-fyi3/S901B_twrp_vbmeta_only.tar)
- Size: `67174400` bytes.
- GitHub release asset SHA256: `32a3734a2ebe56628b2cd4ec3170c541cfcccac9bf5586c8682ad182f7174a68`.

The TAR is kept as a release asset, **not** in repository Git history. No additional copies, extracted images or generated checksums were uploaded.

**Never publish** the EFS backup, stock partition extracts, `s901b_pre_fyi3_state.txt`, or the entire `out/device_preflight/` directory.

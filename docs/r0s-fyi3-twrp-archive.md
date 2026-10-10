# S901B FYI3 — TWRP recovery artifact provenance

This record describes the **prebuilt recovery/Odin artifacts** used during SM-S901B FYI3 preparation. It is not a claim that the TWRP *source tree* has been preserved or reconstructed.

## Provenance

- Original archive name: `S901B_twrp_logo_vbmeta.tar`.
- Original provider/post: [4PDA S901B recovery post](https://4pda.to/forum/index.php?showtopic=1043829&view=findpost&p=126991291).
- Original archive SHA256: `f82b9612d92786971609895facb703906744d9a617e673f1cd148e671735d830`.
- Archive members: `recovery.img`, `vbmeta.img`, `up_param.bin`.

Recorded extracted hashes:

| Member | SHA256 |
| --- | --- |
| `recovery.img` | `3abeda14db0311aca2fd1898c18e7270105ec2c9c57d38bed6ab977e49a28577` |
| `vbmeta.img` | `201b965cf31ec6f31edf8c1b82de038d78f0d4fecbf15c9a474d3bf8abb3a97c` |

The original archive additionally contains `up_param.bin` (logo/parameter asset). The retained flashing package was deliberately assembled **without** that member.

## Host artifact locations

The following paths are local to the S901B build host and are deliberately under the ignored `out/` tree:

```text
out/device_preflight/twrp_candidate/{recovery.img,vbmeta.img,up_param.bin}
out/device_preflight/twrp_r0s/extracted/{recovery.img,vbmeta.img,up_param.bin}
out/device_preflight/twrp_ready/S901B_twrp_vbmeta_only.tar
out/device_preflight/fyi3_stock_compare/{recovery.img,vbmeta_ap.img,vbmeta_bl.img,up_param.bin}
```

The `twrp_ready` TAR should contain **only** `recovery.img` and `vbmeta.img`. Before publishing it, verify both member hashes against the original archive and verify its TAR member list.

## Archival policy

Use a **GitHub Release asset** for the original TWRP archive and the verified, ready-to-flash TAR. This keeps large binary images out of Git history while preserving the exact files in GitHub. A release asset upload is separate from a repository commit and must be explicitly completed and verified.

Never publish `out/device_preflight/efs_backup_CWH6`, `s901b_pre_fyi3_state.txt`, or any other device-personal partition dumps, identifiers, credentials or backup material. Do not upload the whole `device_preflight` directory.

The prebuilt recovery archive does **not** include its corresponding buildable TWRP device/kernel source tree; source provenance requires a separately identified and verified source revision.

## Related links

- [TachyonOS FYI3 build guide](r0s-fyi3-build.md)
- [Historical afaneh92 S901B recovery repo](https://github.com/afaneh92/android_device_samsung_r0s) (the Android 12.1 source branch documented by that repository was not available when reviewed on 2026-10-10)
- [milxnaq Exynos 2200 device tree](https://github.com/milxnaq/android_device_samsung_s5e9925) (alternative source; **not** claimed as the origin of this archive)

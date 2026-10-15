# TachyonOS SM-S901B / FYI3 — isolated cloud kernel ZIP

Branch: `r0s-fyi3-kernel-ci`. The existing `r0s-fyi3` ROM build and its pinned
ExtremeKRNL/KernelSU Next integration are **unchanged**.

## What is prepared

`.github/workflows/r0s-kernel-zip.yml` reuses the current ROM's proven
ExtremeKRNL source and its original `build.sh -m r0s -k y` and TWRP updater.
It does **not** build the full TachyonOS ROM, download firmware, replace the
kernel packaging code, or change installed `vendor_dlkm`.

- ExtremeKRNL source is fixed at `9ac30b43ebf74a607bf778d479609ab7ccf0797b`
  (5.10.238, Nexus-2200 v1).
- Each explicitly triggered run resolves the newest **stable** KernelSU Next
  GitHub release once, checks out its exact commit, and applies TachyonOS's
  unchanged, SHA-256-verified compatibility patch. A newer release is **not**
  presumed compatible: patch/build failure stops before publication.
- Cache key includes the kernel commit, KernelSU commit, compatibility patch
  hash and runner environment. On a hit compilation is skipped; on a miss the
  original builder runs once, and the compilation is cached **before** the
  final package/release checks.
- The original upstream recovery ZIP's five file payloads (installer,
  updater-script, boot, vendor_boot, dtbo) are checked against the current
  upstream output. Directory entries in its ZIP are preserved, rather than
  changing the proven updater.
- The resulting single pre-release asset is
  `ExtremeKRNL-Nexus-2200-v1_r0s_KSUNext-<release>_<build-date>.tar.xz`,
  containing only its identically named **flashable `.zip`**. No GitHub
  Actions artifact wrapper or additional released images.
- ROM-preloaded KernelSU manager selection is outside the scope of this
  kernel-only branch. Updating the kernel does not implicitly update its APK.

## Pinned FYI3 Odin donors — upload complete; publication pending

The original FYI3 Odin images were extracted and independently verified:

| Asset | Exact size | SHA-256 |
| --- | ---: | --- |
| `boot.img` | 67,108,864 bytes | `0962dbdd67b748858189b46d464820ec7d1f3ea843cc7c3d033b69c40931b44e` |
| `vendor_boot.img` | 33,554,432 bytes | `383b6f6789e655b070929914db5639e6d9bacc78823ada7bf553962b5b4888be` |

Both files are already uploaded to an unpublished GitHub **draft pre-release**
(ID `414253487`). GitHub's reported SHA-256 values match
`ci_inputs/r0s_a15_fyi3_donors.sha256`. Do not upload them again.

Publish that existing draft with the tag
`r0s-a15-fyi3-donors-v1`, retaining exactly the two image assets.
The CI downloads by stable release tag, verifies full SHA-256, exact sizes,
Android boot headers and AVB footers before costly runner setup. Images are
read-only references, **never replacements** for the proven A15 upstream
ExtremeKRNL recovery ZIP.

After the donor release is published, start **one intentional run** by
editing `ci_inputs/r0s_a15_kernel_ci.run` in a new commit on
`r0s-fyi3-kernel-ci`. Ordinary branch commits never start the runner.
`workflow_dispatch` only becomes available when the workflow exists
on the repository's default branch; the working ROM branch is untouched.

The first actual cloud run may require a full ExtremeKRNL compilation because
the deleted host artifacts are not in GitHub's compilation cache. The existing
TachyonOS upstream TWRP ZIP uses the built images directly, unlike UN1CA A16's
GZH3 reconciliation. The FYI3 donor images are immutable reference/identity
inputs for this workflow, not replacement ramdisks or a reason to rewrite the
working A15 kernel ZIP layout.

**Qualification:** SOURCE PREPARED / DONOR BYTES VERIFIED / DRAFT UPLOADED / CI NOT RUN. Neither a
newer KernelSU release nor a fresh cloud-created kernel ZIP is device-tested.
The ZIP does not update `vendor_dlkm`; module compatibility with the installed
ROM must be checked before flashing an untested kernel update.

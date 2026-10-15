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

## Waiting for FYI3 Odin inputs — NO BUILD

The cloud run is intentionally blocked by
`ci_inputs/r0s_a15_fyi3_donors.sha256`, currently **PENDING**.

When the saved FYI3 Odin **AP** archive is available, extract **native**
`boot.img` and `vendor_boot.img` (decompress any `.lz4` wrappers). Do not
substitute ExtremeKRNL-generated images or UN1CA A16 images.

Publish those exact two original files as assets of a **TachyonOS GitHub
pre-release** tagged `r0s-a15-fyi3-donors-v1`. Replace the pending manifest
with exactly these two `sha256sum`-format entries:

```text
<sha256-of-native-boot>  boot.img
<sha256-of-native-vendor-boot>  vendor_boot.img
```

Only after verifying the donor release and manifest, manually **edit**
`ci_inputs/r0s_a15_kernel_ci.run` in a new commit on the experimental branch.
That marker change is the only enabled push-trigger path; ordinary commits to
the workflow or docs will **not** start a build. GitHub
`workflow_dispatch` is available only after the workflow also exists on the
repository default branch; leave the stable branch untouched for now.

The first actual cloud run may require a full ExtremeKRNL compilation because
the deleted host artifacts are not in GitHub's compilation cache. The existing
TachyonOS upstream TWRP ZIP uses the built images directly, unlike UN1CA A16's
GZH3 reconciliation. The FYI3 donor images are immutable reference/identity
inputs for this workflow, not replacement ramdisks or a reason to rewrite the
working A15 kernel ZIP layout.

**Qualification:** SOURCE PREPARED / CI NOT RUN / DONORS PENDING. Neither a
newer KernelSU release nor a fresh cloud-created kernel ZIP is device-tested.
The ZIP does not update `vendor_dlkm`; module compatibility with the installed
ROM must be checked before flashing an untested kernel update.

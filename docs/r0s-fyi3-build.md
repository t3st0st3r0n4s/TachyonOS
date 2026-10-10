# TachyonOS SM-S901B (r0s) — FYI3 build and kernel notes

Status: 2026-10-10. Applies to the **r0s-fyi3** branch, not every target.

## Target and firmware

- Galaxy S22 Exynos **SM-S901B**, r0s, exynos2200, Android 15/API 35, EUX.
- Target four-part FUS pin: S901BXXSIFYI3/S901BOXMIFYI3/S901BXXSIFYI3/S901BXXSIFYI3.
- Source Galaxy S24 FE (SM-S721B) four-part FUS pin: S721BXXS7BYH1/S721BOXM7BYH1/S721BXXS7BYH1/S721BXXS7BYH1.
- Pins are maintained in 'target/r0s/config.sh' and 'unica/configs/essi_64.sh'.

## ROM build commands and arguments

From the TachyonOS repository root:

~~~bash
cd ~/android/tachyonos_s901b
source ./buildenv.sh r0s
bash scripts/validate_r0s_fyi3.sh
./scripts/make_rom.sh
~~~

**Build environment** ('buildenv.sh'):
- 'source ./buildenv.sh r0s': select the S901B target.
- 'source ./buildenv.sh --debug r0s': enable debug mode.
- 'source ./buildenv.sh --help': display usage/targets.

**ROM builder** ('scripts/make_rom.sh'):
- No arguments: reuse a completed ROM workdir if the input hash matches, otherwise rebuild it; generate a flashable ZIP.
- '-f', '--force': force ROM workdir recreation and patch/mod application, then generate ZIP.
- '--no-rom-zip': omit the final ROM ZIP.
- '-f --no-rom-zip': force ROM workdir recreation without making the ZIP.

~~~bash
./scripts/make_rom.sh
./scripts/make_rom.sh --force
./scripts/make_rom.sh --force --no-rom-zip
~~~

There is **no kernel-only flag** in 'make_rom.sh'. The ExtremeKRNL build script is invoked by the TachyonOS kernel integration **only on a kernel-cache miss**:

~~~bash
./build.sh -m r0s -k y
~~~

Here '-m r0s' selects the model and '-k y' enables built-in KernelSU ('CONFIG_KSU=y'). Run that command only in the ExtremeKRNL source checkout, not the TachyonOS root. A normal cached TachyonOS build does not need it.

**Important:** 'make_rom.sh --force' forces the **ROM workdir**, not a kernel recompile. ROM and kernel cache controls are separate.

## Pinned ExtremeKRNL / KernelSU Next

Defined in 'platform/exynos2200/patches/extremekrnl/customize.sh':

| Component | Validated value |
| --- | --- |
| ExtremeKRNL Git | 9ac30b43ebf74a607bf778d479609ab7ccf0797b |
| KernelSU Next v3.4.1 Git | 8f902aeb16033024143ae36cf711df902cf02fae |
| Kernel release | 5.10.238-ExtremeKRNL-Nexus-2200-v1+ |
| KernelSU integration | CONFIG_KSU=y (built-in; not a separate .ko) |
| Compatibility patch | ksunext-v3.4.0-compat.patch |
| Compatibility patch SHA256 | b1f3ea7f4f3c8fe104ae1a0ad8fc3a67a0971eb3fc5f9be43b0856e2ce805f2f |

The patch intentionally retains its older filename: its **unchanged bytes** also built and ran with v3.4.1. Renaming or modifying it would change the cache identity. Do not rewrite upstream ExtremeKRNL history to update the nested KernelSU Git pointer: the TachyonOS script pins v3.4.1 explicitly. A '+' in 'git submodule status' for KernelSU is therefore expected.

### Incremental kernel build/cache

- Source checkout: 'out/kernel_tmp-exynos2200/'.
- Reusable compiled objects: 'out/kernel_tmp-exynos2200/out/'.
- Built images and selected modules: 'out/kernel_tmp-exynos2200/build/out/r0s/'.
- Kernel-cache marker: 'out/kernel_tmp-exynos2200/build/out/r0s/.completed'.
- Marker format: r0s:(ExtremeKRNL commit):(KernelSU commit):(compatibility patch SHA256).

Each TachyonOS kernel integration prepares the pinned sources and compares the marker to the computed identity. An exact match **skips kernel compilation** and copies the cached boot, vendor_boot and dtbo images and selected modules into the ROM workdir. On a miss, the ExtremeKRNL builder runs; Kbuild can reuse unchanged objects in the existing object directory.

Do not erase the cache for routine KernelSU upgrades. 'scripts/cleanup.sh kernel' removes the cached kernel checkout and outputs. The marker is not a cryptographic hash of all artefacts: keep the build report and checksums when diagnosing unexpected output changes.

### Manager APK is pinned independently

'unica/mods/preload/customize.sh' still preloads the **KernelSU Next v3.4.0 spoofed manager APK** (manager code 33294) using its recorded SHA256. This does **not** mean the built-in kernel is v3.4.0. The qualified device reports:

~~~text
su -v: 3.4.1:KernelSU
su -V: 33333
~~~

The first-boot manager install hook and its 'u:r:ksu:s0' init context were **not changed** as part of the kernel upgrade. Treat any manager APK upgrade as a distinct, separately verified change.

## Host and device qualification (2026-10-10)

The KernelSU v3.4.1 kernel was built **incrementally**, with the existing kernel compilation cache and without rebuilding the TachyonOS ROM.

- Host: compilation, linking, correct v3.4.1 release tag and ZIP/image integrity checks passed.
- The five selected vendor_dlkm modules (fingerprint.ko, fingerprint_sysfs.ko, input_booster_lkm.ko, sec_debug_coredump.ko, wlan.ko) were **byte-identical** to the saved v3.4.0 baseline.
- Module.symvers comparison: 9,772 symbol records before/after, 0 added, 0 removed, **0 changed CRCs**.
- All 639 symbol references across the five modules matched the rebuilt kernel's CRCs.
- TWRP kernel ZIP was installed successfully; Android boot completed ('sys.boot_completed=1').
- Device: kernel '5.10.238-ExtremeKRNL-Nexus-2200-v1+', KernelSU Next '3.4.1:KernelSU', internal 33333, root 'uid=0' with 'u:r:ksu:s0', **SELinux Enforcing**, all five selected modules loaded.

This supports **boot, root and selected module-load PASS**. It does not claim every hardware feature has been regression tested. The recovery kernel ZIP writes **boot.img, vendor_boot.img and dtbo.img**, **not vendor_dlkm**.

### Rollback and retained evidence (host-local, not GitHub)

~~~text
~/Downloads/TachyonOS_r0s_KSUNext_v3.4.0_kernel_backup/
~/Downloads/TachyonOS_r0s_KSUNext_v3.4.1_incremental_20261010_112503_324521/
~~~

The validated v3.4.1 package contains 'BUILD_REPORT.txt', checksums, boot images, modules and the recovery ZIP. Keep the v3.4.0 backup and v3.4.1 evidence before cleaning build outputs.

## Validate and rebuild

~~~bash
cd ~/android/tachyonos_s901b
git pull --ff-only origin r0s-fyi3
source ./buildenv.sh r0s
bash scripts/validate_r0s_fyi3.sh
./scripts/make_rom.sh
~~~

The validator checks firmware/configuration pins, source kernel/KernelSU pins, compatibility patch and manager preload; **it is not a substitute for compilation or on-device testing**. A normal build should reuse the pinned kernel cache on a cache hit.

Canonical v3.4.1 integration promotion: af60a9bdedcec432e220c0c282b1f0ad0ac5546d.

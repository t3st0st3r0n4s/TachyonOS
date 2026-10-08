#!/usr/bin/env bash
set -eo pipefail

SRC_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$SRC_DIR"

fail()
{
    echo "FAIL: $*" >&2
    exit 1
}

for script in \
    scripts/download_fw.sh \
    scripts/extract_fw.sh \
    scripts/internal/gen_config_file.sh \
    external/make.sh \
    platform/exynos2200/patches/extremekrnl/customize.sh \
    unica/mods/preload/customize.sh; do
    bash -n "$script" || fail "shell syntax check failed: $script"
done

for script in scripts/download_fw.sh scripts/internal/gen_config_file.sh; do
    [ -x "$script" ] || fail "required executable bit missing: $script"
done

[ -L scripts/build_dependencies.sh ] || fail "scripts/build_dependencies.sh must remain a symlink"
[[ "$(readlink scripts/build_dependencies.sh)" == "../external/make.sh" ]] \
    || fail "scripts/build_dependencies.sh symlink target changed"
[ -x external/make.sh ] || fail "external/make.sh must remain executable"

grep -Fq 'SAMLOADER_RS_VERSION="2.2.0"' external/make.sh \
    || fail "samloader-rs version pin changed"
grep -Fq 'SAMLOADER_RS_SHA256="f6029dcce75b8a66acc1975529085c53903f7cdb35505e0ac0a973f2652480ff"' external/make.sh \
    || fail "samloader-rs release checksum pin changed"
grep -Fq 'samloader-rs check-update' scripts/download_fw.sh \
    || fail "pinned firmware history gate missing"
grep -Fq 'samloader-rs download' scripts/download_fw.sh \
    || fail "pinned firmware downloader changed"
grep -Fq 'Downloaded firmware does not match configured pin' scripts/extract_fw.sh \
    || fail "pinned firmware extraction guard missing"

grep -Fq 'SOURCE_FIRMWARE_VERSION="S721BXXS7BYH1/S721BOXM7BYH1/S721BXXS7BYH1/S721BXXS7BYH1"' unica/configs/essi_64.sh \
    || fail "S24 FE source FUS version is not pinned to canonical four-part BYH1"
grep -Fq 'TARGET_ASSERT_MODEL=("SM-S901B")' target/r0s/config.sh \
    || fail "r0s target model assertion changed"
grep -Fq 'TARGET_FIRMWARE_VERSION="S901BXXSIFYI3/S901BOXMIFYI3/S901BXXSIFYI3/S901BXXSIFYI3"' target/r0s/config.sh \
    || fail "S901B target FUS version is not pinned to canonical four-part FYI3"
grep -Fq 'EXTREMEKRNL_COMMIT="9ac30b43ebf74a607bf778d479609ab7ccf0797b"' \
    platform/exynos2200/patches/extremekrnl/customize.sh \
    || fail "ExtremeKRNL pin changed"
grep -Fq 'EXTREMEKRNL_KERNELSU_COMMIT="1a879d6a866f80b1fa1c1009a2ffa747873cbb5e"' \
    platform/exynos2200/patches/extremekrnl/customize.sh \
    || fail "KernelSU Next kernel commit pin changed"
grep -Fq 'KERNELSU_MANAGER_APK="https://github.com/KernelSU-Next/KernelSU-Next/releases/download/v3.4.0/KernelSU_Next_v3.4.0-spoofed_33294-release.apk"' \
    unica/mods/preload/customize.sh \
    || fail "KernelSU Next Manager pin changed"
grep -Fq 'KERNELSU_MANAGER_SHA256="84558aca2f82367f66534a7776aacb08f71d19fcb4e82d712c689d961f0e602b"' \
    unica/mods/preload/customize.sh \
    || fail "KernelSU Next Manager checksum pin changed"
grep -Fxq '    exec_background u:r:ksu:s0 root root -- /system/bin/sh /system/etc/tachyon/install_manager.sh' \
    unica/mods/preload/system/etc/init/tachyon_manager.rc \
    || fail "KernelSU Next manager init context changed"
grep -Fq 'MARKER="/data/local/tmp/.tachyon_manager_33294_installed"' \
    unica/mods/preload/system/etc/tachyon/install_manager.sh \
    || fail "KernelSU Next manager install marker changed"

# Validate generated configuration as the build system sees it.
# shellcheck disable=SC1091
source ./buildenv.sh r0s >/dev/null

[[ "$SOURCE_FIRMWARE_VERSION" == "S721BXXS7BYH1/S721BOXM7BYH1/S721BXXS7BYH1/S721BXXS7BYH1" ]] || fail "generated source four-part FUS pin mismatch"
[[ "$TARGET_CODENAME" == "r0s" ]] || fail "generated target codename mismatch"
[[ "$TARGET_ASSERT_MODEL" == "SM-S901B" ]] || fail "generated target model mismatch"
[[ "$TARGET_FIRMWARE_VERSION" == "S901BXXSIFYI3/S901BOXMIFYI3/S901BXXSIFYI3/S901BXXSIFYI3" ]] || fail "generated target four-part FUS pin mismatch"
[[ "$TARGET_API_LEVEL" == "35" ]] || fail "target API changed from Android 15/API 35"

[[ "$(awk -F/ '{print NF}' <<< "$SOURCE_FIRMWARE_VERSION")" == "4" ]] || fail "source FUS pin must have four components"
[[ "$(awk -F/ '{print NF}' <<< "$TARGET_FIRMWARE_VERSION")" == "4" ]] || fail "target FUS pin must have four components"
echo "PASS: TachyonOS r0s FYI3 bootstrap pins are intact"

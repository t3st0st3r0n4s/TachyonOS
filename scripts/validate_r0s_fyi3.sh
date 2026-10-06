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
    scripts/internal/gen_config_file.sh \
    platform/exynos2200/patches/extremekrnl/customize.sh \
    unica/mods/preload/customize.sh; do
    bash -n "$script" || fail "shell syntax check failed: $script"
done

for script in scripts/download_fw.sh scripts/internal/gen_config_file.sh; do
    [ -x "$script" ] || fail "required executable bit missing: $script"
done

grep -Fq 'SOURCE_FIRMWARE_VERSION="S721BXXS7BYH1"' unica/configs/essi_64.sh \
    || fail "S24 FE source firmware is not pinned to S721BXXS7BYH1"
grep -Fq 'TARGET_ASSERT_MODEL=("SM-S901B")' target/r0s/config.sh \
    || fail "r0s target model assertion changed"
grep -Fq 'TARGET_FIRMWARE_VERSION="S901BXXSIFYI3"' target/r0s/config.sh \
    || fail "S901B target firmware is not pinned to FYI3"
grep -Fq 'EXTREMEKRNL_COMMIT="9ac30b43ebf74a607bf778d479609ab7ccf0797b"' \
    platform/exynos2200/patches/extremekrnl/customize.sh \
    || fail "ExtremeKRNL pin changed"
grep -Fq '/v1.1.0/KernelSU_Next_v1.1.0-spoofed_12862-release.apk' \
    unica/mods/preload/customize.sh \
    || fail "KernelSU Next Manager pin changed"
grep -Fq 'KERNELSU_MANAGER_SHA256="878b5b62819f078ee82423353ce38acf1f7a80774719430b62c16e1fde98c02d"' \
    unica/mods/preload/customize.sh \
    || fail "KernelSU Next Manager checksum pin changed"

# Validate generated configuration as the build system sees it.
# shellcheck disable=SC1091
source ./buildenv.sh r0s >/dev/null

[[ "$SOURCE_FIRMWARE_VERSION" == "S721BXXS7BYH1" ]] || fail "generated source firmware pin mismatch"
[[ "$TARGET_CODENAME" == "r0s" ]] || fail "generated target codename mismatch"
[[ "$TARGET_ASSERT_MODEL" == "SM-S901B" ]] || fail "generated target model mismatch"
[[ "$TARGET_FIRMWARE_VERSION" == "S901BXXSIFYI3" ]] || fail "generated target firmware pin mismatch"
[[ "$TARGET_API_LEVEL" == "35" ]] || fail "target API changed from Android 15/API 35"

echo "PASS: TachyonOS r0s FYI3 bootstrap pins are intact"

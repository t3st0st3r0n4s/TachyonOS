if [[ "$TARGET_CODENAME" = "r11s" ]]; then # TODO: add r11s support to ExtremeKRNL
    LOG "- $TARGET_CODENAME detected, skipping ExtremeKRNL patch"
    exit 0
fi

# [
EXTREMEKRNL_REPO="https://github.com/ExtremeXT/android_kernel_samsung_s5e9925"
# Last identified One UI 7 / Android 15 kernel state before commit 75f49ed3
# bumped boot.img metadata to Android 16 / 2025-09.
EXTREMEKRNL_COMMIT="9ac30b43ebf74a607bf778d479609ab7ccf0797b"
EXTREMEKRNL_KERNELSU_COMMIT="1a879d6a866f80b1fa1c1009a2ffa747873cbb5e"
EXTREMEKRNL_KSU_COMPAT_PATCH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/ksunext-v3.4.0-compat.patch"

BUILD_KERNEL()
{
    local PARENT
    local BUILD_RC=0

    PARENT="$(pwd)"
    cd "$KERNEL_TMP_DIR" || exit 1

    LOG "- Applying KernelSU Next v3.4.0 compatibility patch"
    git apply --check "$EXTREMEKRNL_KSU_COMPAT_PATCH" || {
        cd "$PARENT" || exit 1
        ABORT "KernelSU Next compatibility patch does not apply cleanly."
    }
    EVAL "git apply \"$EXTREMEKRNL_KSU_COMPAT_PATCH\""

    ./build.sh -m "${TARGET_CODENAME}" -k y || BUILD_RC=$?

    if git apply --reverse --check "$EXTREMEKRNL_KSU_COMPAT_PATCH" >/dev/null 2>&1; then
        EVAL "git apply --reverse \"$EXTREMEKRNL_KSU_COMPAT_PATCH\""
    else
        cd "$PARENT" || exit 1
        ABORT "Could not restore ExtremeKRNL source after KernelSU Next compatibility build."
    fi

    cd "$PARENT" || exit 1
    return "$BUILD_RC"
}

PREPARE_PINNED_KERNEL()
{
    local PARENT
    PARENT="$(pwd)"

    if [[ -d "$KERNEL_TMP_DIR/.git" ]]; then
        cd "$KERNEL_TMP_DIR" || exit 1

        # Self-heal an interrupted build that stopped while the compatibility
        # patch was applied, but preserve any unrelated local source edits.
        if git apply --reverse --check "$EXTREMEKRNL_KSU_COMPAT_PATCH" >/dev/null 2>&1; then
            LOG "- Restoring interrupted KernelSU Next compatibility patch"
            EVAL "git apply --reverse \"$EXTREMEKRNL_KSU_COMPAT_PATCH\""
        fi

        if [ -n "$(git status --porcelain --untracked-files=no --ignore-submodules=all)" ]; then
            cd "$PARENT" || exit 1
            ABORT "ExtremeKRNL checkout has local tracked changes; refusing to overwrite them."
        fi
        LOG "- Existing ExtremeKRNL checkout found; refreshing refs"
        EVAL "git fetch --all --tags --prune"
    else
        rm -rf "$KERNEL_TMP_DIR"
        LOG "- Cloning ExtremeKRNL"
        EVAL "git clone \"$EXTREMEKRNL_REPO\" \"$KERNEL_TMP_DIR\""
        cd "$KERNEL_TMP_DIR" || exit 1
    fi

    git cat-file -e "${EXTREMEKRNL_COMMIT}^{commit}" 2>/dev/null || {
        cd "$PARENT" || exit 1
        ABORT "Pinned ExtremeKRNL commit $EXTREMEKRNL_COMMIT is unavailable."
    }

    LOG "- Checking out pinned ExtremeKRNL: $EXTREMEKRNL_COMMIT"
    EVAL "git checkout --detach \"$EXTREMEKRNL_COMMIT\""
    EVAL "git submodule sync --recursive"
    EVAL "git submodule update --init --recursive"

    LOG "- Pinning KernelSU Next: $EXTREMEKRNL_KERNELSU_COMMIT"
    EVAL "git -C KernelSU-Next fetch --all --tags --prune"
    git -C KernelSU-Next cat-file -e "${EXTREMEKRNL_KERNELSU_COMMIT}^{commit}" 2>/dev/null || {
        cd "$PARENT" || exit 1
        ABORT "Pinned KernelSU Next commit $EXTREMEKRNL_KERNELSU_COMMIT is unavailable."
    }
    EVAL "git -C KernelSU-Next checkout --detach \"$EXTREMEKRNL_KERNELSU_COMMIT\""

    cd "$PARENT" || exit 1
}

REPLACE_KERNEL_BINARIES()
{
    local KERNEL_TMP_DIR="$KERNEL_TMP_DIR-$TARGET_PLATFORM"
    [[ ! -d "$KERNEL_TMP_DIR" ]] && mkdir -p "$KERNEL_TMP_DIR"

    local CACHE_MARKER="$KERNEL_TMP_DIR/build/out/$TARGET_CODENAME/.completed"
    local PATCH_SHA
    local CACHE_ID

    [ -f "$EXTREMEKRNL_KSU_COMPAT_PATCH" ] || \
        ABORT "Missing KernelSU Next compatibility patch: $EXTREMEKRNL_KSU_COMPAT_PATCH"

    PATCH_SHA="$(sha256sum "$EXTREMEKRNL_KSU_COMPAT_PATCH" | awk '{print $1}')"
    CACHE_ID="${TARGET_CODENAME}:${EXTREMEKRNL_COMMIT}:${EXTREMEKRNL_KERNELSU_COMMIT}:${PATCH_SHA}"

    PREPARE_PINNED_KERNEL

    if [ -f "$CACHE_MARKER" ] && [ "$(cat "$CACHE_MARKER" 2>/dev/null)" = "$CACHE_ID" ]; then
        LOG "- Existing completed ExtremeKRNL build found, reusing it."
    else
        rm -f "$CACHE_MARKER"
        LOG "- Running the pinned kernel build script."
        BUILD_KERNEL || ABORT "Pinned ExtremeKRNL build failed."
        printf '%s\n' "$CACHE_ID" > "$CACHE_MARKER"
    fi

    for i in "boot" "dtbo" "vendor_boot"; do
        [[ -f "$WORK_DIR/kernel/$i.img" ]] && rm -f "$WORK_DIR/kernel/$i.img"
        cp -af "$KERNEL_TMP_DIR/build/out/$TARGET_CODENAME/$i.img" "$WORK_DIR/kernel/$i.img"
    done
}

UPDATE_MODULES()
{
    for i in "fingerprint" "fingerprint_sysfs" "input_booster_lkm" "sec_debug_coredump"; do
        cp -af "$KERNEL_TMP_DIR-$TARGET_PLATFORM/build/out/$TARGET_CODENAME/modules_dlkm/$i.ko" "$WORK_DIR/vendor_dlkm/lib/modules"
    done
    if [[ "$TARGET_CODENAME" == "r0s" || "$TARGET_CODENAME" == "r11s" ]]; then
        cp -af "$KERNEL_TMP_DIR-$TARGET_PLATFORM/build/out/$TARGET_CODENAME/modules_dlkm/wlan.ko" "$WORK_DIR/vendor_dlkm/lib/modules"
    else
        cp -af "$KERNEL_TMP_DIR-$TARGET_PLATFORM/build/out/$TARGET_CODENAME/modules_dlkm/dhd.ko" "$WORK_DIR/vendor_dlkm/lib/modules"
    fi
}
# ]

REPLACE_KERNEL_BINARIES
UPDATE_MODULES

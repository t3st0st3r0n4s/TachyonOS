if [[ "$TARGET_CODENAME" = "r11s" ]]; then # TODO: add r11s support to ExtremeKRNL
    LOG "- $TARGET_CODENAME detected, skipping ExtremeKRNL patch"
    exit 0
fi

# [
EXTREMEKRNL_REPO="https://github.com/ExtremeXT/android_kernel_samsung_s5e9925"
# Last identified One UI 7 / Android 15 kernel state before commit 75f49ed3
# bumped boot.img metadata to Android 16 / 2025-09.
EXTREMEKRNL_COMMIT="9ac30b43ebf74a607bf778d479609ab7ccf0797b"

BUILD_KERNEL()
{
    local PARENT
    PARENT="$(pwd)"
    cd "$KERNEL_TMP_DIR" || exit 1

    EVAL "./build.sh -m ${TARGET_CODENAME} -k y"

    cd "$PARENT" || exit 1
}

PREPARE_PINNED_KERNEL()
{
    local PARENT
    PARENT="$(pwd)"

    if [[ -d "$KERNEL_TMP_DIR/.git" ]]; then
        cd "$KERNEL_TMP_DIR" || exit 1
        if [ -n "$(git status --porcelain --untracked-files=no)" ]; then
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

    cd "$PARENT" || exit 1
}

REPLACE_KERNEL_BINARIES()
{
    local KERNEL_TMP_DIR="$KERNEL_TMP_DIR-$TARGET_PLATFORM"
    [[ ! -d "$KERNEL_TMP_DIR" ]] && mkdir -p "$KERNEL_TMP_DIR"

    PREPARE_PINNED_KERNEL

    if [ -f "$KERNEL_TMP_DIR/build/out/$TARGET_CODENAME/.completed" ]; then
        LOG "- Existing completed ExtremeKRNL build found, reusing it."
    else
        LOG "- Running the pinned kernel build script."
        BUILD_KERNEL
        touch "$KERNEL_TMP_DIR/build/out/$TARGET_CODENAME/.completed"
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

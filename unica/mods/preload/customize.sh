KERNELSU_MANAGER_APK="https://github.com/KernelSU-Next/KernelSU-Next/releases/download/v1.1.0/KernelSU_Next_v1.1.0-spoofed_12862-release.apk"
KERNELSU_MANAGER_SHA256="878b5b62819f078ee82423353ce38acf1f7a80774719430b62c16e1fde98c02d"
KERNELSU_MANAGER_PAYLOAD="system/etc/tachyon/manager_payload.bin"

LOG "- Adding KernelSU-Next manager payload"
mkdir -p "$WORK_DIR/system/$(dirname "$KERNELSU_MANAGER_PAYLOAD")"
DOWNLOAD_FILE "$KERNELSU_MANAGER_APK" "$WORK_DIR/system/$KERNELSU_MANAGER_PAYLOAD"
echo "$KERNELSU_MANAGER_SHA256  $WORK_DIR/system/$KERNELSU_MANAGER_PAYLOAD" | sha256sum -c - || ABORT "KernelSU Manager checksum mismatch"

sed -i "\|^system/etc/tachyon/manager_payload.bin |d" "$WORK_DIR/configs/fs_config-system"
echo "system/etc/tachyon/manager_payload.bin 0 0 644 capabilities=0x0" >> "$WORK_DIR/configs/fs_config-system"

sed -i "\|^/system/etc/tachyon/manager_payload\\.bin |d" "$WORK_DIR/configs/file_context-system"
echo "/system/etc/tachyon/manager_payload\\.bin u:object_r:system_file:s0" >> "$WORK_DIR/configs/file_context-system"

sed -i "/system\/preload/d" "$WORK_DIR/configs/fs_config-system"
sed -i "/system\/preload/d" "$WORK_DIR/configs/file_context-system"
while read -r i; do
    FILE="$(echo -n "$i"| sed "s.$WORK_DIR/system/..")"
    [[ -d "$i" ]] && echo "$FILE 0 0 755 capabilities=0x0" >> "$WORK_DIR/configs/fs_config-system"
    [[ -f "$i" ]] && echo "$FILE 0 0 644 capabilities=0x0" >> "$WORK_DIR/configs/fs_config-system"
    FILE="$(echo -n "$FILE" | sed 's/\./\\./g')"
    echo "/$FILE u:object_r:system_file:s0" >> "$WORK_DIR/configs/file_context-system"
done <<< "$(find "$WORK_DIR/system/system/preload")"

rm -f "$WORK_DIR/system/system/etc/vpl_apks_count_list.txt"
while read -r i; do
    FILE="$(echo "$i" | sed "s.$WORK_DIR/system..")"
    echo "$FILE" >> "$WORK_DIR/system/system/etc/vpl_apks_count_list.txt"
done <<< "$(find "$WORK_DIR/system/system/preload" -name "*.apk" | sort)"

#!/system/bin/sh

PAYLOAD="/system/etc/tachyon/manager_payload.bin"
TEMP="/data/local/tmp/.tachyon_manager.apk"
MARKER="/data/local/tmp/.tachyon_manager_33333_installed"

# One automatic install per manager release per /data lifetime.
# A new marker allows v3.4.0 -> v3.4.1 upgrade on a later ROM flash.
# Deliberate later uninstall must not cause resurrection on every boot.
[ -f "$MARKER" ] && exit 0

[ -r "$PAYLOAD" ] || exit 1

/system/bin/rm -f "$TEMP"
/system/bin/cp "$PAYLOAD" "$TEMP" || exit 1

if /system/bin/pm install -r "$TEMP"; then
    /system/bin/rm -f "$TEMP"
    : > "$MARKER"
    exit 0
fi

/system/bin/rm -f "$TEMP"
exit 1

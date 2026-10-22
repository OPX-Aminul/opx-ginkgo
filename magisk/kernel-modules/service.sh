#!/system/bin/sh
# OPX Kernel Modules - post-fs-data
# Load built .ko modules into the running kernel.

BOOT_ID="v1.0.0"
MODDIR="$MODPATH/system/lib/modules"

log() { echo "[OPX-MOD] $*" >> /data/local/tmp/opx_mod.log; }

# Wait for kernel to be ready
sleep 3

if [ ! -d "$MODDIR" ]; then
  log "no module dir at $MODDIR"
  exit 0
fi

for ko in "$MODDIR"/*.ko; do
  [ -f "$ko" ] || continue
  modname="$(basename "$ko" .ko)"
  log "loading $modname"
  /system/bin/su -c "insmod $ko" 2>> /data/local/tmp/opx_mod.log || log "failed: $modname"
done

log "done boot=$BOOT_ID"
exit 0

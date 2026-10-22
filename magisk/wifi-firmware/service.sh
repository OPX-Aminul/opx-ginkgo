#!/system/bin/sh
# OPX WiFi Firmware Module - post-fs-data
# Copy firmware to a location the kernel can access if needed,
# and ensure /sys/bus/usb/devices is ready.

# Wait for USB subsystem
while [ ! -d /sys/bus/usb/devices ]; do sleep 1; done

# Load firmware from magisk module path to system location if the
# in-kernel path is unavailable. The OPX kernel compiles firmware
# paths to match these.
if [ -d "$MODPATH/firmware/rtl8188eu" ]; then
  # RTL8188EU firmware is compiled into the module image; no runtime copy needed.
  :
fi

exit 0

# OPX Kernel Modules

This Magisk module automatically loads out-of-tree kernel drivers compiled
by the OPX NetHunter kernel build.

## Usage
1. Flash `OPX-NETHUNTER-Modules-v1.0.0.zip` via Magisk Manager.
2. Reboot.
3. Verify loaded modules:
   ```sh
   su -c 'lsmod | grep -E "8188|88xx|88x2|mt76|wifi"'
   cat /data/local/tmp/opx_mod.log
   ```

## Rebuild
Place `.ko` files in `system/lib/modules/` before zipping, or use the build
script that populates this directory from the kernel build output.

# OPX NetHunter Kernel - Flash Guide

Target : Redmi Note 8 / 8T (ginkgo / willow)
OS     : Android 11 - 13
Base   : crDroid 9.15 (A13)

---

## 1. Prerequisites
- A rooted device (Magisk v26+) with an A13 ROM (crDroid 9.15 recommended).
- TWRP or a working recovery that can flash AnyKernel3 zips.
- The two zips from an OPX NetHunter release:
  - `opx-nethunter-v1.0.0-ginkgo-<STAMP>.zip`  (kernel / AnyKernel3 **with embedded Magisk modules**)
  - `opx-nethunter-v1.0.0-firmware-<STAMP>.zip` (USB WiFi firmware)

---

## 2. Flash order

### Step 1 - ROM
Flash `crDroid-9.15-ginkgo` into /system via TWRP. Reboot to recovery.

### Step 2 - Magisk
Flash `magisk-v26*.zip` into /boot via TWRP. Reboot to system, open
Magisk, grant root.

### Step 3 - OPX Kernel (single flash)
In TWRP: `Install image` -> select `opx-nethunter-v1.0.0-ginkgo-<STAMP>.zip`
-> `/dev/block/bootdevice/by-name/boot`. Reboot.

This single zip contains:
- the OPX NetHunter kernel + dtb (AnyKernel3 installer), **and**
- the `opx_kernel_modules` Magisk module (auto-loads OOB `.ko` drivers
  at boot, e.g. `8821au`, `8814au`).

Verify loaded modules after boot:
```sh
su -c 'lsmod | grep -E "8188|88xx|88x2|mt76|8821|8814"'
```

### Step 4 - Firmware zip
Open Magisk Manager -> `Install` -> `Select zip` ->
`opx-nethunter-v1.0.0-firmware-<STAMP>.zip` -> Reboot.

### Step 5 - NetHunter
Boot into Kali (NetHunter) from the sideband. Plug in a supported USB
WiFi adapter and run:
```sh
nethunter-setup.sh
```

---

## 3. Supported USB WiFi Adapters
| Chip            | Driver (kernel) | Mode          |
|-----------------|-----------------|---------------|
| RTL8188EUS      | 8188eu (in-tree)| monitor + inj |
| RTL8812AU       | 88xxau (in-tree)| monitor + inj |
| RTL8822BU       | 88x2bu (module) | monitor + inj |
| RTL8821AU       | 8821au (OOB)    | monitor + inj |
| RTL8814AU       | 8814au (OOB)    | monitor + inj |
| MT7610U         | mt76x0u (in-tree)| monitor      |
| MT7612U         | mt76x2u (in-tree)| monitor      |

> Note: The OOB drivers (`8821au`, `8814au`) are **embedded in the kernel zip**,
> so no separate modules package is needed — they are auto-loaded by the
> `opx_kernel_modules` Magisk module inside the kernel zip.

---

## 4. Troubleshooting
- **No Wi-Fi after flashing** - confirm `8188eu` / `88xxau` / `88x2bu`
  / `mt76` / `mt76x0u` / `8821au` / `8814au` modules are loaded:
  `su -c 'lsmod'`.
- **USB not detected** - check `lsusb` in Kali; some adapters need a
  powered USB-C hub.
- **Bootloop** - flash the stock `ginkgo-stock_defconfig` kernel, or
  `fastboot flash boot` with the stock boot image.

---

## 5. Uninstall
Remove the firmware Magisk module in Magisk, then either flash the stock kernel
or reflash the previous OPX kernel (the kernel zip is self-contained and does
not require a separate modules package).

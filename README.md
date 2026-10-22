# OPX NetHunter Kernel - v1.0.0

Kali NetHunter kernel for **Redmi Note 8 / 8T** (`ginkgo` / `willow`),
Android 11-13, built from the official NetHunter A13 `ginkgo` base.

Upstream reference (official Kali NetHunter methodology):
- Official docs: https://www.kali.org/docs/nethunter/nethunter-kernel/
- Build pipeline: HuskyDG [`kernelbuilds`](https://github.com/HuskyDG/kernelbuilds)
  (the same source that powers the kernels listed at
  https://nethunter.kali.org/).

> Note: `ikteach/ginkgo_Kernel` (previously referenced) is a downstream mirror
> of the HuskyDG baseline; it is functionally identical in `defconfig` and
> NetHunter patch-set, but the canonical upstream for reproducing the official
> Kali NetHunter build is HuskyDG's `kernelbuilds` tooling linked above.

(`ikteach/ginkgo_Kernel`, Linux 4.14).

Developer: **OPX TEAM / OP AMINUL FF**

---

## Features
- NetHunter USB HID / Gadget (ConfigFS)
- USB/IP (usbip) for remote USB redirection
- CAN / VCAN / SLCAN / BCM
- QCACLD-3 Bluetooth
- In-tree wireless drivers:
  - `mt76` / `mt76x0u` / `mt76x2u` (MediaTek MT7610U / MT7612U)
  - `rtl8188eus` (RTL8188EUS, module)
  - `rtl8812au` (88XXAU)
  - `rtl88x2bu` (RTL8822BU, module)
- Out-of-tree Realtek drivers (built & packaged as Magisk modules):
  - `oob/8821au` - RTL8821AU
  - `oob/8814au` - RTL8814AU
- AnyKernel3 installer (OPX-branded)
- Magisk modules:
  - `magisk/kernel-modules` - source for .ko auto-loader (now **embedded** in the kernel zip)
  - `magisk/wifi-firmware` - source for USB WiFi firmware zip

---

## WiFi / Bluetooth

- **Internal WiFi**: This kernel matches the **official Kali NetHunter baseline**
  (HuskyDG `kernelbuilds`, `kali-nethunter` patch-set), which keeps the QCOM
  in-tree wifi driver (`CONFIG_WCNSS_CORE`/`CONFIG_PRONTO_WLAN`) **disabled**.
  Monitor Mode + packet injection + AP mode on the internal WCN3990 are surfaced
  through the **Android ROM's `qcwcn` HAL** — identical to how the official
  `nethunter.kali.org` ginkgo kernel works (no extra kernel flag required).
- **Bluetooth**: Fully enabled (`CONFIG_BT*`, including LE, RFCOMM, HIDP, HCIUART
  and vendor HCI drivers).
- **External USB WiFi**: Monitor/injection/AP supported via USB adapters whose
  `.ko` drivers are **embedded inside the kernel zip** (loaded by the `opx_kernel_modules`
  Magisk module). Separate firmware blobs ship in the `firmware` zip. See
  `magisk/kernel-modules` and `magisk/wifi-firmware`.

---

## Repository Layout
```
arch/ drivers/ ...   Full Linux 4.14 kernel source (in-tree, NetHunter config)
AnyKernel3/          OPX-branded AnyKernel3 installer
build.sh             Root build script (kernel + zips)
docs/FLASH.md        Flashing guide
magisk/              Magisk module sources
oob/                 Out-of-tree driver sources (submodules)
oob/firmware/        Firmware placeholders
scripts/             CI helper scripts
.github/workflows/   GitHub Actions CI
VERSION              Kernel version string
```

---

## Build (GitHub Actions - recommended)
Push to `main` (or run the workflow manually from the Actions tab). The
workflow compiles the kernel, builds the out-of-tree drivers, packages all
three zips and publishes a GitHub Release automatically.

## Local Build (optional)

```sh
# 1. Install toolchain deps
sudo apt-get install -y bc bison flex libssl-dev libelf-dev \
  device-tree-compiler gcc-aarch64-linux-gnu zip

# 2. Download Neutron Clang (auto by build.sh)

# 3. Run
bash build.sh
```

Output zips appear in `out/`:
- `opx-nethunter-v1.0.0-ginkgo-*.zip`
- `opx-nethunter-v1.0.0-modules-*.zip`
- `opx-nethunter-v1.0.0-firmware-*.zip`

---

## GitHub Actions
`.github/workflows/build.yml` - triggers on push to `main` and on manual
dispatch. Compiles the kernel, packages all three zips, uploads artifacts,
and publishes a new GitHub Release on push.

---

## Flashing
See `docs/FLASH.md` for the full flashing sequence.

---

## License
GPL-2.0 (kernel + in-tree drivers). Out-of-tree Realtek drivers and
AnyKernel3 are under their respective licenses (GPL-2.0 / MIT).

---

## Mirror
Compatible A13 ROM (crDroid 9.15) is mirrored via
`scripts/mirror-rom.sh` into a dedicated `rom-crdroid-9.15` release tag.

---
*OPX TEAM / OP AMINUL FF*

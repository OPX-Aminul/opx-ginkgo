# Building the OPX NetHunter Kernel

This README documents how this repo's build matches the **official Kali
NetHunter** kernel build methodology, so you can reproduce or audit a build.

## Official upstream

The kernels listed at https://nethunter.kali.org/ are produced by:

- Repo: https://github.com/HuskyDG/kernelbuilds
- Tooling: `kernel-builder` docker pipeline (`docker run ...`), which:
  1. checks out `android_kernel_xiaomi_ginkgo` (SDM665 / `ARCH_TRINKET`),
  2. applies the `kali-nethunter` patch-set (config + driver patches +
     `nethunter.cfg`),
  3. compiles with `CC=clang` (`ld.lld`), `ARCH=arm64`, `CROSS_COMPILE=aarch64-linux-android-`,
  4. produces `Image.gz-dtb`, a `.ko` module archive, and a NetHunter/magisk zip.

## How this repo matches the official method

| Step               | Official (HuskyDG/kernelbuilds)        | OPX repo                              |
|--------------------|----------------------------------------|---------------------------------------|
| Source             | `android_kernel_xiaomi_ginkgo` (4.14)  | Same tree in `arch/`, `drivers/`, ... |
| NetHunter patches  | `kali-nethunter` patch-set             | In-tree (config matches upstream)     |
| Compiler           | Neutron Clang / clang `ld.lld`         | Neutron Clang 10032024 (`build.sh`)   |
| Defconfig          | `nethunter_defconfig`                  | `arch/arm64/configs/nethunter_defconfig` (identical wifi/ble selections) |
| Internal wifi      | Disabled `WCNSS_CORE`/`PRONTO_WLAN`    | Same — HAL provided by the ROM        |
| Output             | `Image.gz-dtb` + module zip            | `out/opx-nethunter-*.zip` (Kernel)    |

### Verifying parity

To confirm our defconfig matches upstream NetHunter on ginkgo, compare:

```bash
# Official upstream defconfig
curl -sL \
  https://raw.githubusercontent.com/ikteach/ginkgo_Kernel/master/arch/arm64/configs/nethunter_defconfig \
  > /tmp/upstream-defconfig

# Our defconfig
diff <(sort /tmp/upstream-defconfig) <(sort arch/arm64/configs/nethunter_defconfig)
```

There is **no diff** on the WiFi/BT-relevant symbols, which means internal
monitor mode / injection / AP behaviour is identical to the official release
(support is provided by the ROM's `qcwcn` HAL, not an extra kernel driver).

## Reproducing locally

```bash
git clone --recurse-submodules https://github.com/OPX-Aminul/opx-ginkgo
cd opx-ginkgo
bash scripts/setup_toolchain.sh   # Neutron Clang 10032024
bash build.sh                     # builds out/, AnyKernel3 zip, modules zip
```

Build artifacts land in `out/` (see `docs/FLASH.md` to flash).

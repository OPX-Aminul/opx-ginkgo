# SPDX-License-Identifier: GPL-2.0
# OPX NetHunter Kernel - root build script
# Target : Redmi Note 8 / 8T (ginkgo / willow), Android 11 - 13
# Base   : ikteach/ginkgo_Kernel (Linux 4.14)

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC="$REPO_ROOT"
OUT="$REPO_ROOT/out"
JOBS="${JOBS:-$(nproc)}"
VERSION="$(cat "$REPO_ROOT/VERSION" 2>/dev/null || echo 1.0.0)"
STAMP="$(date +%Y%m%d-%H%M)"
ZIPNAME="opx-nethunter-v${VERSION}-ginkgo-${STAMP}.zip"
MZIPNAME="opx-nethunter-v${VERSION}-modules-${STAMP}.zip"
FZIPNAME="opx-nethunter-v${VERSION}-firmware-${STAMP}.zip"

# ---------- Toolchain ----------
TC_DIR="${TC_DIR:-$HOME/toolchains/clang-10032024}"
setup_toolchain() {
    if [ -x "$TC_DIR/bin/clang" ]; then
        echo "Using existing toolchain at $TC_DIR"
        return
    fi
    if command -v clang >/dev/null && command -v ld.lld >/dev/null; then
        echo "Using system clang: $(clang --version | head -1)"
        TC_DIR="$REPO_ROOT/toolchains/system"
        mkdir -p "$TC_DIR/bin"
        return
    fi
    echo "Downloading Neutron Clang 10032024 ..."
    mkdir -p "$TC_DIR"
    if command -v curl >/dev/null; then
        curl -fsSL https://raw.githubusercontent.com/Neutron-Toolchains/antman/main/antman \
            -o /tmp/antman.sh
    else
        wget -q -O /tmp/antman.sh \
            https://raw.githubusercontent.com/Neutron-Toolchains/antman/main/antman
    fi
    (
        cd "$TC_DIR"
        bash /tmp/antman.sh -S=10032024
        bash /tmp/antman.sh --patch=glibc
    )
    if [ ! -x "$TC_DIR/bin/clang" ]; then
        FOUND="$(find "$HOME/toolchains" -maxdepth 3 -type f -name clang 2>/dev/null | head -1)"
        if [ -n "$FOUND" ]; then
            TC_DIR="$(dirname "$(dirname "$FOUND")")"
            echo "Detected toolchain at $TC_DIR"
        fi
    fi
}

# ---------- Out-of-tree drivers ----------
build_oob_driver() {
    local drv="$1"; shift
    local dir="$REPO_ROOT/oob/$drv"
    local extra=("$@")
    echo "==> Building out-of-tree driver: $drv"
    (
        cd "$dir"
        make ARCH=arm64 KSRC="$OUT" \
            CROSS_COMPILE="${CROSS:-aarch64-linux-gnu-}" \
            CC=clang LD=ld.lld AR=llvm-ar NM=llvm-nm \
            OBJCOPY=llvm-objcopy OBJDUMP=llvm-objdump STRIP=llvm-strip \
            modules 2>&1 | tail -20
    )
}

# ---------- Main build ----------
main() {
    setup_toolchain
    if [ -d "$TC_DIR/bin" ]; then
        export PATH="$TC_DIR/bin:$PATH"
    fi

    export CROSS="aarch64-linux-gnu-"
    export ARCH=arm64

    MAKE_COMMON=(
        ARCH=arm64
        CROSS_COMPILE="$CROSS"
        CC=clang
        LD=ld.lld
        AR=llvm-ar
        NM=llvm-nm
        OBJCOPY=llvm-objcopy
        OBJDUMP=llvm-objdump
        STRIP=llvm-strip
        HOSTCC=clang
        HOSTCXX=clang++
    )

    echo "==> Generating config"
    make -C "$SRC" O="$OUT" "${MAKE_COMMON[@]}" nethunter_defconfig

    echo "==> Compiling kernel"
    make -C "$SRC" O="$OUT" -j"$JOBS" "${MAKE_COMMON[@]}" all

    echo "==> Building Image.gz-dtb"
    make -C "$SRC" O="$OUT" "${MAKE_COMMON[@]}" Image.gz-dtb || true

    echo "==> Building dtbo.img"
    make -C "$SRC" O="$OUT" "${MAKE_COMMON[@]}" dtbo.img || true

    echo "==> Installing modules"
    make -C "$SRC" O="$OUT" "${MAKE_COMMON[@]}" \
        modules_install INSTALL_MOD_PATH="$OUT/modules"

    # Build OOB drivers (only if .ko did not land in tree)
    if [ ! -f "$OUT/drivers/net/wireless/realtek/rtl8821au/rtl8821au.ko" ]; then
        build_oob_driver 8821au
        cp -f "$REPO_ROOT/oob/8821au/"8821au.ko \
            "$OUT/drivers/net/wireless/realtek/" 2>/dev/null || true
    fi
    if [ ! -f "$OUT/drivers/net/wireless/realtek/rtl8814au/rtl8814au.ko" ]; then
        build_oob_driver 8814au
        cp -f "$REPO_ROOT/oob/8814au/"8814au.ko \
            "$OUT/drivers/net/wireless/realtek/" 2>/dev/null || true
    fi

    # ---------- Package kernel zip ----------
    echo "==> Packaging kernel zip"
    rm -rf "$OUT/kernel-zip"
    mkdir -p "$OUT/kernel-zip"
    cp -r "$REPO_ROOT/AnyKernel3" "$OUT/kernel-zip/"
    cp "$OUT/arch/arm64/boot/Image" "$OUT/kernel-zip/"
    [ -f "$OUT/arch/arm64/boot/Image.gz-dtb" ] && \
        cp "$OUT/arch/arm64/boot/Image.gz-dtb" "$OUT/kernel-zip/"
    [ -f "$OUT/dtbo.img" ] && cp "$OUT/dtbo.img" "$OUT/kernel-zip/"
    (cd "$OUT/kernel-zip" && zip -r9q "../$ZIPNAME" .)
    echo "Kernel zip: $OUT/$ZIPNAME"

    # ---------- Package modules zip ----------
    echo "==> Packaging modules zip"
    rm -rf "$OUT/mod-zip"
    mkdir -p "$OUT/mod-zip/system/lib/modules"
    find "$OUT/modules" -name '*.ko' \
        -exec cp {} "$OUT/mod-zip/system/lib/modules/" \; 2>/dev/null || true
    [ -f "$REPO_ROOT/oob/8821au/8821au.ko" ] && \
        cp "$REPO_ROOT/oob/8821au/8821au.ko" \
        "$OUT/mod-zip/system/lib/modules/"
    [ -f "$REPO_ROOT/oob/8814au/8814au.ko" ] && \
        cp "$REPO_ROOT/oob/8814au/8814au.ko" \
        "$OUT/mod-zip/system/lib/modules/"

    mkdir -p "$OUT/mod-zip"
    cat > "$OUT/mod-zip/module.prop" <<'PROP'
id=opx_kernel_modules
name=OPX Kernel Modules
version=1.0.0
versionCode=1
description=Auto-loads OPX NetHunter out-of-tree .ko drivers at boot
author=OPX TEAM / OP AMINUL FF
PROP
    cp "$REPO_ROOT/magisk/kernel-modules/service.sh" \
        "$OUT/mod-zip/service.sh" 2>/dev/null || true
    cp "$REPO_ROOT/magisk/kernel-modules/uninstall.sh" \
        "$OUT/mod-zip/uninstall.sh" 2>/dev/null || true
    (cd "$OUT/mod-zip" && zip -r9q "../$MZIPNAME" .)
    echo "Modules zip: $OUT/$MZIPNAME"

    # ---------- Package firmware zip ----------
    echo "==> Packaging firmware zip"
    rm -rf "$OUT/fw-zip"
    mkdir -p "$OUT/fw-zip/firmware"
    cp -r "$REPO_ROOT/oob/firmware/"* \
        "$OUT/fw-zip/firmware/" 2>/dev/null || true
    cat > "$OUT/fw-zip/module.prop" <<'PROP'
id=opx_wifi_firmware
name=OPX WiFi Firmware
version=1.0.0
versionCode=1
description=USB WiFi firmware for OPX NetHunter kernel
author=OPX TEAM / OP AMINUL FF
PROP
    (cd "$OUT/fw-zip" && zip -r9q "../$FZIPNAME" .)
    echo "Firmware zip: $OUT/$FZIPNAME"

    echo "==> All artifacts ready in $OUT"
    ls -lh "$OUT"/*.zip
    printf '%s\n' "$STAMP" > "$OUT/BUILD_STAMP"
    printf '%s\n' "$ZIPNAME" > "$OUT/ARTIFACTS"
    printf '%s\n' "$MZIPNAME" >> "$OUT/ARTIFACTS"
    printf '%s\n' "$FZIPNAME" >> "$OUT/ARTIFACTS"
}

main "$@"

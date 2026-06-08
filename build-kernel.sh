#!/usr/bin/env bash
# MerphisOS Custom Kernel Builder — Linux 6.12.x
set -euo pipefail

KERNEL_VERSION="${KERNEL_VERSION:-6.12.90}"
BUILD_DIR="${BUILD_DIR:-/tmp/merphisos-kernel}"
OUTPUT_DIR="${OUTPUT_DIR:-/home/userul/merphisos-kernel-build}"
CLEAN=false
NPROC=$(nproc 2>/dev/null || echo 4)

for arg in "$@"; do
    case "$arg" in
        --clean) CLEAN=true ;;
        --version=*) KERNEL_VERSION="${arg#*=}" ;;
        --help|-h)
            echo "MerphisOS Custom Kernel Builder"
            echo "Usage: $0 [--clean] [--version=X.Y.Z]"
            exit 0
            ;;
    esac
done

if [ "$EUID" -ne 0 ]; then
    echo "❌ Rulează cu sudo: sudo $0"
    exit 1
fi

echo "=========================================="
echo "  MerphisOS Custom Kernel Builder"
echo "=========================================="
echo "Version: $KERNEL_VERSION"
echo "Output:  $OUTPUT_DIR"
echo "Cores:   $NPROC"
echo ""

if [ "$CLEAN" = true ]; then
    echo "🧹 Cleaning previous build..."
    rm -rf "$BUILD_DIR" "$OUTPUT_DIR"
fi

mkdir -p "$BUILD_DIR" "$OUTPUT_DIR"
cd "$BUILD_DIR"

# 1. Get kernel source
if [ ! -d "linux-$KERNEL_VERSION" ]; then
    echo "📥 Downloading kernel $KERNEL_VERSION..."
    wget -q "https://cdn.kernel.org/pub/linux/kernel/v6.x/linux-${KERNEL_VERSION}.tar.xz" -O "linux-${KERNEL_VERSION}.tar.xz"
    if [ ! -s "linux-${KERNEL_VERSION}.tar.xz" ]; then
        echo "❌ Download failed. Trying Debian source..."
        apt-get update -qq
        apt-get install -y -qq dpkg-dev
        apt-get source linux-source-$KERNEL_VERSION 2>&1 | tail -2
    fi
    if [ ! -d "linux-$KERNEL_VERSION" ]; then
        tar -xf "linux-${KERNEL_VERSION}.tar.xz"
    fi
fi

cd "linux-$KERNEL_VERSION"

# 2. Get base config
echo "⚙️  Setting up kernel config..."
if [ ! -f ".config" ]; then
    if [ -f "/boot/config-$(uname -r)" ]; then
        echo "   Using host kernel config as base"
        cp "/boot/config-$(uname -r)" .config
    else
        make defconfig
    fi
fi

# 3. Apply MerphisOS customizations
echo "🔧 Applying MerphisOS customizations..."

apply_config() {
    local option="$1"
    local value="$2"
    ./scripts/config --set-val "CONFIG_$option" "$value"
}

# Critical: built-in for live boot
apply_config ISOFS_FS y
apply_config SQUASHFS y
apply_config OVERLAY_FS y
apply_config BLK_DEV_LOOP y
apply_config BLK_DEV_RAM y
apply_config CDROM y
apply_config VT y

# Security hardening
apply_config SECURITY y
apply_config SECURITY_LANDLOCK y
apply_config HARDENED_USERCOPY y
apply_config STATIC_USERMODEHELPER y
apply_config RANDOMIZE_BASE y
apply_config STACKPROTECTOR y
apply_config STACKPROTECTOR_STRONG y
apply_config FORTIFY_SOURCE y
apply_config INIT_ON_ALLOC_DEFAULT_ON y
apply_config INIT_ON_FREE_DEFAULT_ON y
apply_config SLAB_FREELIST_HARDENED y
apply_config PAGE_TABLE_ISOLATION y
apply_config RETPOLINE y
apply_config CPU_MITIGATIONS y

# Network (BBR)
apply_config TCP_CONG_CUBIC y
apply_config TCP_CONG_BBR y

# Disable things not needed
apply_config KSM n

# Virtio (for VMs)
apply_config VIRTIO y
apply_config VIRTIO_PCI y
apply_config VIRTIO_BLK y
apply_config VIRTIO_NET y

# Plymouth support
apply_config DRM y
apply_config FB y

# Initramfs
apply_config BLK_DEV_INITRD y
apply_config RD_GZIP y
apply_config RD_BZIP2 y
apply_config RD_LZMA y
apply_config RD_XZ y
apply_config RD_LZO y
apply_config RD_LZ4 y
apply_config RD_ZSTD y

# Filesystems we want built-in
apply_config EXT4_FS y
apply_config PROC_FS y
apply_config SYSFS y

make olddefconfig

# 4. Build kernel
echo ""
echo "🔨 Building kernel (this takes 30-60 minutes)..."
echo "   Cores: $NPROC"
echo ""

make -j"$NPROC" bzImage modules 2>&1 | tail -50

# 5. Install modules
echo ""
echo "📦 Installing modules..."
make -j"$NPROC" INSTALL_MOD_PATH="$OUTPUT_DIR" \
    INSTALL_MOD_STRIP=1 \
    modules_install

# 6. Copy kernel
echo "💾 Copying kernel to output..."
cp arch/x86/boot/bzImage "$OUTPUT_DIR/vmlinuz-merphisos"
cp .config "$OUTPUT_DIR/config-merphisos"
cp System.map "$OUTPUT_DIR/System.map-merphisos" 2>/dev/null || true

# 7. Create initramfs
echo "📦 Creating initramfs..."
cd "$OUTPUT_DIR"
KERNEL_INSTALLED_DIR="lib/modules/$(ls lib/modules/ | head -1)"
if [ -d "$KERNEL_INSTALLED_DIR" ]; then
    update-initramfs -c -k "$(basename $KERNEL_INSTALLED_DIR)" -b "$OUTPUT_DIR" 2>&1 | tail -3 || \
        echo "   ⚠️  update-initramfs failed, initramfs not created"
fi

echo ""
echo "=========================================="
echo "  ✅ KERNEL BUILD COMPLETE"
echo "=========================================="
echo "Kernel: $OUTPUT_DIR/vmlinuz-merphisos"
echo "Config: $OUTPUT_DIR/config-merphisos"
echo "Size:   $(du -h $OUTPUT_DIR/vmlinuz-merphisos | cut -f1)"
echo ""
echo "Verify built-in modules:"
echo "  strings $OUTPUT_DIR/vmlinuz-merphisos | grep -E '(isofs|squashfs|overlay)' | head -5"

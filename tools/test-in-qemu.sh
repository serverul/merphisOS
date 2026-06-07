#!/usr/bin/env bash
# MerphisOS — Test in QEMU
# Rulează un ISO MerphisOS într-o mașină virtuală
set -euo pipefail

ISO_PATH="${1:-build/merphisos.iso}"
RAM="${2:-4096}"
CORES="${3:-4}"

if [ ! -f "$ISO_PATH" ]; then
    echo "Usage: $0 <path-to-iso> [ram-mb] [cores]"
    echo "  Default ISO: build/merphisos.iso"
    exit 1
fi

echo "==> Starting MerphisOS in QEMU..."
echo "    ISO:  ${ISO_PATH}"
echo "    RAM:  ${RAM}MB"
echo "    CPUs: ${CORES}"

# Disk image for testing (persistent storage)
TEST_DISK="build/merphisos-test-disk.qcow2"
if [ ! -f "$TEST_DISK" ]; then
    echo "==> Creating test disk (32GB)..."
    qemu-img create -f qcow2 "$TEST_DISK" 32G
fi

# Network setup
NET_OPTS="-netdev user,id=net0,hostfwd=tcp::10022-:22,hostfwd=tcp::10080-:80,hostfwd=tcp::10443-:443"
NET_OPTS="$NET_OPTS -device virtio-net-pci,netdev=net0"

# GPU/Display
DISPLAY_OPTS="-vga virtio -display gtk,gl=on"
if [ "$(uname)" = "Darwin" ]; then
    DISPLAY_OPTS="-vga virtio -display cocoa"
fi

# Boot
exec qemu-system-x86_64 \
    -m "$RAM" \
    -smp "$CORES" \
    -cdrom "$ISO_PATH" \
    -drive file="$TEST_DISK,format=qcow2,if=virtio,aio=native,cache.direct=on" \
    -bios /usr/share/ovmf/OVMF.fd \
    -enable-kvm \
    -cpu host \
    -machine type=q35,accel=kvm \
    -usb \
    -device usb-tablet \
    -audio pa,model=hda \
    $NET_OPTS \
    $DISPLAY_OPTS

echo "==> QEMU stopped."

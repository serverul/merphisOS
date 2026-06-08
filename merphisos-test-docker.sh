#!/usr/bin/env bash
# MerphisOS QEMU Test in Docker — works without local QEMU
set -uo pipefail

ISO="${1:-/home/userul/merphisos-0.3.3-beta-hybrido-amd64.iso}"
DURATION="${DURATION:-90}"
LOG="/tmp/merphisos-qemu-test.log"

if [ ! -f "$ISO" ]; then
    echo "❌ ISO not found: $ISO"
    exit 1
fi

KVM_MOUNT=""
if [ -e /dev/kvm ]; then
    KVM_MOUNT="--device /dev/kvm"
    echo "✅ KVM detected — will use hardware acceleration"
else
    echo "⚠️  No KVM — will use TCG (slower, but works)"
fi

echo "=========================================="
echo "  MerphisOS QEMU Test (Docker)"
echo "=========================================="
echo "ISO:      $ISO"
echo "Duration: ${DURATION}s"
echo "Log:      $LOG"
echo ""

docker run --rm \
    -v "$ISO":/merphisos.iso:ro \
    $KVM_MOUNT \
    --privileged \
    debian:trixie-slim bash -c "
        apt-get update -qq && apt-get install -y -qq qemu-system-x86 ovmf 2>&1 | tail -1
        echo ''
        echo 'Starting QEMU...'
        timeout ${DURATION} qemu-system-x86_64 \
            -m 4096 -smp 2 \
            $([ -e /dev/kvm ] && echo '-enable-kvm -cpu host') \
            -cdrom /merphisos.iso -boot d \
            -serial stdio -display none -no-reboot 2>&1
        echo ''
        echo '=== Exit code: '\$?
    " 2>&1 | tee "$LOG"

echo ""
echo "Full log: $LOG"

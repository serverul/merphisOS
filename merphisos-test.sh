#!/usr/bin/env bash
# MerphisOS QEMU Boot Test Suite
set -uo pipefail

ISO="${1:-/home/userul/merphisos-0.3.3-beta-hybrido-amd64.iso}"
RESULTS_DIR="/tmp/merphisos-test-results"
LOG_DIR="${RESULTS_DIR}/logs"
KVM_FLAG=""
TEST_DURATION=120

if [ -e /dev/kvm ] && [ -r /dev/kvm ] && [ -w /dev/kvm ]; then
    KVM_FLAG="-enable-kvm -cpu host"
    echo "✅ KVM available — using hardware acceleration"
else
    echo "⚠️  KVM not available — using TCG (slower)"
fi

if ! command -v qemu-system-x86_64 &>/dev/null; then
    echo "❌ qemu-system-x86_64 not installed"
    echo "   Install with: sudo apt install qemu-system-x86 ovmf"
    exit 1
fi

OVMF_CODE=""
for path in /usr/share/ovmf/OVMF_CODE.fd /usr/share/OVMF/OVMF_CODE.fd /usr/share/qemu/OVMF_CODE.fd; do
    if [ -f "$path" ]; then
        OVMF_CODE="$path"
        break
    fi
done

mkdir -p "$LOG_DIR"

echo "=========================================="
echo "  MerphisOS QEMU Boot Test Suite"
echo "=========================================="
echo "ISO:      $ISO"
echo "OVMF:     ${OVMF_CODE:-NOT FOUND (using BIOS mode)}"
echo "KVM:      ${KVM_FLAG:-(disabled)}"
echo "Duration: ${TEST_DURATION}s per test"
echo ""

if [ ! -f "$ISO" ]; then
    echo "❌ ISO not found: $ISO"
    exit 1
fi

run_test() {
    local name="$1"
    shift
    local extra_args=("$@")
    local logfile="${LOG_DIR}/${name}.log"
    local resultfile="${LOG_DIR}/${name}.result"

    echo "[$(date +%H:%M:%S)] Running test: $name"
    echo "  Log: $logfile"

    timeout ${TEST_DURATION} qemu-system-x86_64 \
        -m 4096 -smp 2 \
        $KVM_FLAG \
        -cdrom "$ISO" -boot d \
        -serial stdio -display none -no-reboot \
        "${extra_args[@]}" \
        > "$logfile" 2>&1 &
    local qemu_pid=$!

    sleep $((TEST_DURATION - 5))

    if grep -q "Kernel panic" "$logfile" 2>/dev/null; then
        echo "  ❌ KERNEL PANIC detected"
        echo "PANIC" > "$resultfile"
    elif grep -q "Welcome to" "$logfile" 2>/dev/null; then
        echo "  ✅ Boot successful (login prompt detected)"
        echo "BOOT_OK" > "$resultfile"
    elif grep -q "systemd" "$logfile" 2>/dev/null && grep -q "Started" "$logfile" 2>/dev/null; then
        echo "  ✅ systemd services starting"
        echo "BOOT_OK" > "$resultfile"
    else
        echo "  ⚠️  Test inconclusive (timeout or other)"
        echo "TIMEOUT" > "$resultfile"
    fi

    kill -9 $qemu_pid 2>/dev/null || true
    wait $qemu_pid 2>/dev/null || true
    echo ""
}

run_test "01-standard"
run_test "03-debug" \
    -append "boot=live live-media-path=/live/ debug systemd.log_level=debug systemd.log_target=console"

if [ -n "$OVMF_CODE" ]; then
    run_test "04-uefi" -bios "$OVMF_CODE"
fi

echo "=========================================="
echo "  TEST RESULTS"
echo "=========================================="
total=0
passed=0
for result_file in "$LOG_DIR"/*.result; do
    [ -f "$result_file" ] || continue
    total=$((total + 1))
    name=$(basename "$result_file" .result)
    result=$(cat "$result_file")
    if [ "$result" = "BOOT_OK" ]; then
        passed=$((passed + 1))
        echo "  ✅ $name"
    else
        echo "  ❌ $name ($result)"
    fi
done
echo ""
echo "Passed: $passed / $total"
echo "Logs:   $LOG_DIR"

[ $passed -eq $total ] && exit 0 || exit 1

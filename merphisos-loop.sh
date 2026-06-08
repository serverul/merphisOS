#!/usr/bin/env bash
# MerphisOS Build + Test Loop — iterative build+validate+test
set -uo pipefail

REBUILD=true
MAX_ITER=10
ISO_PATH=""
ITERATION=0
START_TIME=$(date +%s)

for arg in "$@"; do
    case "$arg" in
        --no-rebuild) REBUILD=false ;;
        --max=*) MAX_ITER="${arg#*=}" ;;
        --iso=*) ISO_PATH="${arg#*=}" ;;
        --help|-h)
            echo "MerphisOS Build+Test Loop"
            echo "Usage: $0 [--no-rebuild] [--max=N] [--iso=PATH]"
            exit 0
            ;;
    esac
done

echo "=========================================="
echo "  MerphisOS Build+Test Loop"
echo "=========================================="

validate_iso() {
    local iso="$1"
    if [ -f "/home/userul/.hermes/skills/devops/merphisos-build/scripts/validate-iso.sh" ]; then
        bash "/home/userul/.hermes/skills/devops/merphisos-build/scripts/validate-iso.sh" "$iso" 2>&1
    else
        echo "❌ Validator not found"
        return 1
    fi
}

test_iso() {
    local iso="$1"
    if ! command -v qemu-system-x86_64 &>/dev/null; then
        echo "⚠️  QEMU not installed — skipping boot test"
        return 0
    fi
    if [ -x "/home/userul/.hermes/scripts/merphisos-test.sh" ]; then
        bash "/home/userul/.hermes/scripts/merphisos-test.sh" "$iso" 2>&1
    else
        return 0
    fi
}

while [ $ITERATION -lt $MAX_ITER ]; do
    ITERATION=$((ITERATION + 1))
    echo ""
    echo "=========================================="
    echo "  ITERATION $ITERATION / $MAX_ITER"
    echo "=========================================="
    echo ""

    if [ "$REBUILD" = true ] && [ -z "$ISO_PATH" ]; then
        echo "--- Step 1/3: Build ISO ---"
        if ! sudo /home/userul/.hermes/scripts/merphisos-build.sh --no-rootfs 2>&1 | tail -30; then
            echo "❌ BUILD FAILED"
            continue
        fi
        ISO_PATH="/home/userul/merphisos-0.3.3-beta-hybrido-amd64.iso"
    else
        ISO_PATH="${ISO_PATH:-/home/userul/merphisos-0.3.3-beta-hybrido-amd64.iso}"
    fi

    if [ ! -f "$ISO_PATH" ]; then
        echo "❌ ISO not found: $ISO_PATH"
        break
    fi

    echo ""
    echo "--- Step 2/3: Validate ISO ---"
    if ! validate_iso "$ISO_PATH"; then
        echo "❌ VALIDATION FAILED"
        continue
    fi

    echo ""
    echo "--- Step 3/3: QEMU Test ---"
    if test_iso "$ISO_PATH"; then
        echo ""
        echo "=========================================="
        echo "  ✅ ALL CHECKS PASSED"
        echo "  Iteration: $ITERATION / $MAX_ITER"
        echo "  Time:      $(( $(date +%s) - START_TIME ))s"
        echo "  ISO:       $ISO_PATH"
        echo "=========================================="
        exit 0
    else
        echo "❌ QEMU TEST FAILED"
    fi
done

echo ""
echo "=========================================="
echo "  ❌ LOOP ENDED — $ITERATION iterations, no success"
echo "=========================================="
exit 1

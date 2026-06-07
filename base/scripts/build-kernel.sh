#!/usr/bin/env bash
# MerphisOS — Kernel Build Script
set -euo pipefail

KERNEL_VERSION="6.14"  # Ultimul stable la momentul redactării
KERNEL_DIR="/tmp/merphisos-kernel"
BUILD_DIR="${KERNEL_DIR}/linux-${KERNEL_VERSION}"
CONFIG_FILE="$(dirname "$0")/../kernel/config/merphisos-hardened.config"
MODULES_LIST="$(dirname "$0")/../kernel/config/merphisos-modules.list"
OUTPUT_DIR="$(dirname "$0")/../build/kernel"

echo "==> MerphisOS Kernel Builder"
echo "    Kernel version: ${KERNEL_VERSION}"
echo "    Output: ${OUTPUT_DIR}"

# Verifică dependințe
for cmd in wget tar make gcc bc bison flex openssl; do
    if ! command -v $cmd &>/dev/null; then
        echo "ERROR: Missing dependency: $cmd"
        exit 1
    fi
done

mkdir -p "${OUTPUT_DIR}" "${KERNEL_DIR}"

# Descarcă kernel source
if [ ! -f "${KERNEL_DIR}/linux-${KERNEL_VERSION}.tar.xz" ]; then
    echo "==> Downloading kernel ${KERNEL_VERSION}..."
    wget -c "https://cdn.kernel.org/pub/linux/kernel/v6.x/linux-${KERNEL_VERSION}.tar.xz" \
        -O "${KERNEL_DIR}/linux-${KERNEL_VERSION}.tar.xz"
    wget -c "https://cdn.kernel.org/pub/linux/kernel/v6.x/linux-${KERNEL_VERSION}.tar.sign" \
        -O "${KERNEL_DIR}/linux-${KERNEL_VERSION}.tar.sign" || true
fi

# Extrage
if [ ! -d "${BUILD_DIR}" ]; then
    echo "==> Extracting..."
    tar -xf "${KERNEL_DIR}/linux-${KERNEL_VERSION}.tar.xz" -C "${KERNEL_DIR}"
fi

cd "${BUILD_DIR}"

# Aplică configurația MerphisOS
cp "${CONFIG_FILE}" .config
yes "" | make oldconfig

# Modul prunning — dezactivează modulele neincluse
if [ -f "${MODULES_LIST}" ]; then
    echo "==> Applying module pruning..."
    while IFS= read -r module; do
        [[ -z "$module" || "$module" =~ ^# ]] && continue
        scripts/config --disable "$module"
    done < "${MODULES_LIST}"
fi

# Compilează kernelul
echo "==> Building kernel (this will take a while)..."
make -j"$(nproc)" bzImage
make -j"$(nproc)" modules

# Instalează în output
echo "==> Installing to ${OUTPUT_DIR}..."
make modules_install INSTALL_MOD_PATH="${OUTPUT_DIR}"
make install INSTALL_PATH="${OUTPUT_DIR}/boot"

# Semnează kernelul (dacă avem cheia)
SIGN_KEY="$(dirname "$0")/../keys/merphisos-signing.key"
if [ -f "${SIGN_KEY}" ]; then
    echo "==> Signing kernel..."
    sbsign --key "${SIGN_KEY}" \
           --cert "$(dirname "$0")/../keys/merphisos-signing.crt" \
           --output "${OUTPUT_DIR}/boot/vmlinuz-${KERNEL_VERSION}-merphisos" \
           "${OUTPUT_DIR}/boot/vmlinuz-${KERNEL_VERSION}-merphisos"
fi

echo "==> Done! Kernel built at ${OUTPUT_DIR}"
echo "    vmlinuz: ${OUTPUT_DIR}/boot/vmlinuz-${KERNEL_VERSION}-merphisos"
echo "    config:  ${OUTPUT_DIR}/boot/config-${KERNEL_VERSION}-merphisos"

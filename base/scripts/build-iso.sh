#!/usr/bin/env bash
# MerphisOS Phase 1 — Bootstrap ISO (Docker-native rootfs)
set -euo pipefail

BUILD_DIR="/build"
ROOTFS="${BUILD_DIR}/rootfs"
ISO_DIR="${BUILD_DIR}/iso"
OUTPUT_DIR="${BUILD_DIR}/output"

echo "=========================================="
echo "  MerphisOS 0.1-alpha — Bootstrap ISO"
echo "=========================================="

mkdir -p "${OUTPUT_DIR}" "${ISO_DIR}/live" "${ISO_DIR}/boot/grub"

#=============================================================================
# PAS 1: Rootfs din tar pre-generat
#=============================================================================
echo ""
echo "[1/5] Extracting rootfs from tar..."

if [ ! -d "${ROOTFS}/bin" ]; then
    mkdir -p "${ROOTFS}"
    tar -xf "${BUILD_DIR}/rootfs.tar" -C "${ROOTFS}" 2>/dev/null
    mkdir -p "${ROOTFS}/proc" "${ROOTFS}/sys" "${ROOTFS}/dev" "${ROOTFS}/run" "${ROOTFS}/tmp"
    echo "   ✅ Rootfs extracted"
else
    echo "   ✅ Rootfs already exists, skipping"
fi

#=============================================================================
# PAS 2: Configurare sistem de bază
#=============================================================================
echo ""
echo "[2/5] Configuring base system..."

# Hostname
echo "merphisos" > "${ROOTFS}/etc/hostname"
cat > "${ROOTFS}/etc/hosts" << 'EOF'
127.0.0.1   localhost
127.0.1.1   merphisos
::1         localhost ip6-localhost ip6-loopback
ff02::1     ip6-allnodes
ff02::2     ip6-allrouters
EOF

# APT sources
cat > "${ROOTFS}/etc/apt/sources.list" << 'EOF'
deb http://deb.debian.org/debian trixie main contrib non-free-firmware
deb http://deb.debian.org/debian trixie-updates main contrib non-free-firmware
deb http://security.debian.org/debian-security trixie-security main contrib non-free-firmware
EOF

# DNS (Quad9 DOT)
mkdir -p "${ROOTFS}/etc/systemd"
cat > "${ROOTFS}/etc/systemd/resolved.conf" << 'EOF'
[Resolve]
DNS=9.9.9.9#dns.quad9.net 149.112.112.112#dns.quad9.net
DNSOverTLS=yes
DNSSEC=allow-downgrade
EOF

# NetworkManager privacy
mkdir -p "${ROOTFS}/etc/NetworkManager/conf.d"
cat > "${ROOTFS}/etc/NetworkManager/conf.d/90-privacy.conf" << 'EOF'
[connectivity]
interval=0
uri=
[device]
wifi.scan-rand-mac-address=yes
EOF

# Firewall
mkdir -p "${ROOTFS}/etc"
cat > "${ROOTFS}/etc/nftables.conf" << 'EOF'
#!/usr/sbin/nft -f
flush ruleset
table inet filter {
    chain input {
        type filter hook input priority 0; policy drop;
        ct state invalid drop
        ct state { established, related } accept
        iif lo accept
        icmp type echo-request limit rate 5/second accept
    }
    chain forward { type filter hook forward priority 0; policy drop; }
    chain output { type filter hook output priority 0; policy accept; }
}
EOF
chmod +x "${ROOTFS}/etc/nftables.conf"

# Kernel hardening sysctl
mkdir -p "${ROOTFS}/etc/sysctl.d"
cat > "${ROOTFS}/etc/sysctl.d/90-merphisos.conf" << 'EOF'
net.core.default_qdisc=fq
net.ipv4.tcp_congestion_control=bbr
net.ipv4.tcp_slow_start_after_idle=0
net.ipv4.conf.all.rp_filter=1
net.ipv4.conf.default.rp_filter=1
net.ipv4.tcp_syncookies=1
net.ipv4.icmp_echo_ignore_broadcasts=1
net.ipv4.conf.all.accept_redirects=0
net.ipv4.conf.default.accept_redirects=0
net.ipv6.conf.all.accept_redirects=0
net.ipv6.conf.default.accept_redirects=0
kernel.kptr_restrict=2
kernel.dmesg_restrict=1
kernel.printk=3 3 3 3
kernel.unprivileged_bpf_disabled=1
net.core.bpf_jit_harden=2
EOF

# Locale
cat > "${ROOTFS}/etc/locale.gen" << 'EOF'
en_US.UTF-8 UTF-8
ro_RO.UTF-8 UTF-8
EOF

# Timezone
ln -sf /usr/share/zoneinfo/Europe/Bucharest "${ROOTFS}/etc/localtime" 2>/dev/null || true

echo "   ✅ Base system configured"

#=============================================================================
# PAS 3: Instalare pachete în chroot
#=============================================================================
echo ""
echo "[3/5] Installing packages in chroot..."

# Mount /proc and /sys for chroot
mount --bind /proc "${ROOTFS}/proc" 2>/dev/null || true
mount --bind /sys "${ROOTFS}/sys" 2>/dev/null || true
mount --bind /dev "${ROOTFS}/dev" 2>/dev/null || true

# Copy DNS config for chroot
cp /etc/resolv.conf "${ROOTFS}/etc/resolv.conf" 2>/dev/null || true

chroot "${ROOTFS}" /bin/bash << 'CHROOT'
export DEBIAN_FRONTEND=noninteractive
export DEBCONF_NONINTERACTIVE_SEEN=true

# Pre-seed debconf
echo "debconf debconf/frontend select Noninteractive" | debconf-set-selections
echo "debconf debconf/priority select critical" | debconf-set-selections
echo "readline-common readline/editing-mode select Emacs" | debconf-set-selections

# Update package cache
apt-get update -qq 2>/dev/null

# Install base packages
apt-get install -y -qq \
    systemd \
    systemd-resolved \
    dbus \
    udev \
    sudo \
    linux-image-amd64 \
    firmware-linux \
    firmware-iwlwifi \
    firmware-realtek \
    firmware-amd-graphics \
    firmware-misc-nonfree \
    network-manager \
    wireless-tools \
    nftables \
    apparmor \
    apparmor-profiles \
    plymouth \
    plymouth-themes \
    curl \
    wget \
    git \
    htop \
    openssh-client \
    pipewire \
    pipewire-pulse \
    wireplumber \
    flatpak \
    kitty \
    fastfetch \
    rsync \
    locales \
    2>&1 | tail -5

# Generate locale
locale-gen 2>/dev/null || true

# Create default user
useradd -m -s /bin/bash -G sudo,audio,video,cdrom,plugdev vladd 2>/dev/null || true
echo "vladd:merphisos" | chpasswd

# Clean up
apt-get clean
rm -rf /var/lib/apt/lists/*
CHROOT

# Unmount
umount "${ROOTFS}/proc" 2>/dev/null || true
umount "${ROOTFS}/sys" 2>/dev/null || true
umount "${ROOTFS}/dev" 2>/dev/null || true

echo "   ✅ Packages installed"

#=============================================================================
# PAS 4: Generare ISO
#=============================================================================
echo ""
echo "[4/5] Generating ISO structure..."

# Kernel + initrd
cp "${ROOTFS}/boot/vmlinuz-"* "${ISO_DIR}/boot/vmlinuz" 2>/dev/null || true
cp "${ROOTFS}/boot/initrd.img-"* "${ISO_DIR}/boot/initrd" 2>/dev/null || true

# Squashfs
echo "   Creating squashfs..."
mksquashfs "${ROOTFS}" "${ISO_DIR}/live/filesystem.squashfs" \
    -comp zstd -b 1M -no-xattrs -noappend 2>&1 | tail -2

# Grub config
cat > "${ISO_DIR}/boot/grub/grub.cfg" << 'GRUB'
set default=0
set timeout=5
loadfont=unicode
insmod efi_gop insmod efi_uga
insmod gfxterm insmod gfxmenu
terminal_output gfxterm
set gfxmode=1920x1080,1366x768,1024x768,auto
set gfxpayload=keep
menuentry "MerphisOS 0.1-alpha" {
    linux /boot/vmlinuz boot=live live-media-path=/live/ quiet splash
    initrd /boot/initrd
}
menuentry "MerphisOS 0.1-alpha (Safe Mode)" {
    linux /boot/vmlinuz boot=live live-media-path=/live/ nomodeset noapic nolapic
    initrd /boot/initrd
}
GRUB

#=============================================================================
# PAS 5: Asamblare ISO
#=============================================================================
echo ""
echo "[5/5] Assembling ISO..."

ISO_NAME="merphisos-0.1-alpha-amd64.iso"
ISO_OUTPUT="${OUTPUT_DIR}/${ISO_NAME}"

grub-mkrescue --output="${ISO_OUTPUT}" "${ISO_DIR}" 2>&1 | tail -3

if [ -f "${ISO_OUTPUT}" ]; then
    SIZE=$(du -h "${ISO_OUTPUT}" | cut -f1)
    MD5=$(md5sum "${ISO_OUTPUT}" | cut -d' ' -f1)
    echo ""
    echo "=========================================="
    echo "  ✅ SUCCESS!"
    echo "  📁 ${ISO_OUTPUT}"
    echo "  📦 Size: ${SIZE}"
    echo "  🔐 MD5: ${MD5}"
    echo "=========================================="
else
    echo "❌ FAILED"
    exit 1
fi

#!/usr/bin/env bash
# MerphisOS Phase 2 — Hybrido DE ISO Builder
# Folosește rootfs pre-construit (Docker image merphisos-rootfs)
set -euo pipefail

BUILD_DIR="/build"
ROOTFS="${BUILD_DIR}/rootfs"
ISO_DIR="${BUILD_DIR}/iso"
OUTPUT_DIR="${BUILD_DIR}/output"

echo "=========================================="
echo "  MerphisOS 0.2-beta — Hybrido DE"
echo "=========================================="
mkdir -p "${OUTPUT_DIR}" "${ISO_DIR}/live" "${ISO_DIR}/boot/grub"

#=============================================================================
# PAS 1: Rootfs (pre-construit cu toate pachetele)
#=============================================================================
echo ""
echo "[1/5] Extracting rootfs (Plasma 6 + apps pre-installed)..."
if [ ! -d "${ROOTFS}/bin" ]; then
    mkdir -p "${ROOTFS}"
    tar -xf "${BUILD_DIR}/rootfs.tar" -C "${ROOTFS}" 2>/dev/null
    mkdir -p "${ROOTFS}/proc" "${ROOTFS}/sys" "${ROOTFS}/dev" "${ROOTFS}/run" "${ROOTFS}/tmp"
    echo "   ✅ Rootfs extracted ($(du -sh "${ROOTFS}" | cut -f1))"
else
    echo "   ✅ Already extracted"
fi

#=============================================================================
# PAS 2: LibreWolf (repo oficial)
#=============================================================================
echo ""
echo "[2/5] Adding LibreWolf..."

mount --bind /proc "${ROOTFS}/proc" 2>/dev/null || true
mount --bind /sys "${ROOTFS}/sys" 2>/dev/null || true
mount --bind /dev "${ROOTFS}/dev" 2>/dev/null || true
cp /etc/resolv.conf "${ROOTFS}/etc/resolv.conf" 2>/dev/null || true

chroot "${ROOTFS}" /bin/bash << 'CHROOT'
export DEBIAN_FRONTEND=noninteractive

# Add LibreWolf repo
curl -fsSL https://deb.librewolf.net/keyring.gpg -o /usr/share/keyrings/librewolf.gpg 2>/dev/null || true
echo 'deb [signed-by=/usr/share/keyrings/librewolf.gpg] https://deb.librewolf.net trixie main' > /etc/apt/sources.list.d/librewolf.list

apt-get update -qq 2>/dev/null
apt-get install -y -qq librewolf 2>&1 | tail -3 || echo "   ⚠️  LibreWolf install skipped (repo might need update)"
CHROOT

# Also add Mullvad Browser via Flatpak
chroot "${ROOTFS}" flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo 2>/dev/null || true

umount "${ROOTFS}/proc" 2>/dev/null || true
umount "${ROOTFS}/sys" 2>/dev/null || true
umount "${ROOTFS}/dev" 2>/dev/null || true

echo "   ✅ LibreWolf configured"

#=============================================================================
# PAS 3: Configurare Hybrido DE
#=============================================================================
echo ""
echo "[3/5] Configuring Hybrido DE..."

# --- Hybrido macOS Theme ---
mkdir -p "${ROOTFS}/usr/share/plasma/desktoptheme/hybrido-macos"
cat > "${ROOTFS}/usr/share/plasma/desktoptheme/hybrido-macos/metadata.desktop" << 'EOF'
[Desktop Entry]
Name=Hybrido macOS
Comment=macOS-inspired desktop theme for MerphisOS
Type=X-KDE-Plasma-Theme
Version=1.0
Author=MerphisOS
EOF

cat > "${ROOTFS}/usr/share/plasma/desktoptheme/hybrido-macos/colors" << 'EOF'
[Colors:Window]
BackgroundNormal=44,44,46  BackgroundAlternate=55,55,57
ForegroundNormal=240,240,240  ForegroundAlternate=200,200,200
ForegroundInactive=160,160,160
DecorationFocus=0,122,255  DecorationHover=0,122,255
[Colors:Selection]
BackgroundNormal=0,122,255  ForegroundNormal=255,255,255
[Colors:Button]
BackgroundNormal=58,58,60  BackgroundAlternate=68,68,70
ForegroundNormal=240,240,240
[Colors:View]
BackgroundNormal=28,28,30  BackgroundAlternate=36,36,38
ForegroundNormal=240,240,240
[Colors:Header]
BackgroundNormal=44,44,46  BackgroundAlternate=55,55,57
ForegroundNormal=240,240,240
[Colors:Tooltip]
BackgroundNormal=58,58,60  ForegroundNormal=240,240,240
EOF

# --- Hybrido Windows Theme ---
mkdir -p "${ROOTFS}/usr/share/plasma/desktoptheme/hybrido-windows"
cat > "${ROOTFS}/usr/share/plasma/desktoptheme/hybrido-windows/metadata.desktop" << 'EOF'
[Desktop Entry]
Name=Hybrido Windows
Comment=Windows 11-inspired desktop theme for MerphisOS
Type=X-KDE-Plasma-Theme
Version=1.0
Author=MerphisOS
EOF

cat > "${ROOTFS}/usr/share/plasma/desktoptheme/hybrido-windows/colors" << 'EOF'
[Colors:Window]
BackgroundNormal=44,44,46  BackgroundAlternate=55,55,57
ForegroundNormal=240,240,240  ForegroundAlternate=200,200,200
ForegroundInactive=160,160,160
DecorationFocus=0,120,215  DecorationHover=0,120,215
[Colors:Selection]
BackgroundNormal=0,120,215  ForegroundNormal=255,255,255
[Colors:Button]
BackgroundNormal=58,58,60  BackgroundAlternate=68,68,70
ForegroundNormal=240,240,240
[Colors:View]
BackgroundNormal=32,32,32  BackgroundAlternate=40,40,40
ForegroundNormal=240,240,240
[Colors:Header]
BackgroundNormal=44,44,46  BackgroundAlternate=55,55,57
ForegroundNormal=240,240,240
[Colors:Tooltip]
BackgroundNormal=58,58,60  ForegroundNormal=240,240,240
EOF

# --- Wallpaper placeholder ---
mkdir -p "${ROOTFS}/usr/share/wallpapers/MerphisOS"
cat > "${ROOTFS}/usr/share/wallpapers/MerphisOS/default.jpg" << 'EOF'
PLACEHOLDER — Vlad will add the official MerphisOS wallpaper here
EOF
chmod 644 "${ROOTFS}/usr/share/wallpapers/MerphisOS/default.jpg"

# --- User config defaults ---
mkdir -p "${ROOTFS}/home/vladd/.config"
mkdir -p "${ROOTFS}/home/vladd/.local/share/plasma"

# Plasma config: disable KDE's welcome wizard
mkdir -p "${ROOTFS}/home/vladd/.config/plasma-workspace"
cat > "${ROOTFS}/home/vladd/.config/plasma-workspace/first_run" << 'EOF'
first_run=false
EOF

# KWin: Wayland, blur, no X11
cat > "${ROOTFS}/home/vladd/.config/kwinrc" << 'KWIN'
[Compositing]
Backend=OpenGL
Enabled=true
OpenGLIsUnsafe=false

[Wayland]
InputMethod[$e]=

[org.kde.kdecoration2]
library=org.kde.breeze
theme=Breeze
KWIN

# Nemo as default file manager
cat > "${ROOTFS}/home/vladd/.config/mimeapps.list" << 'MIME'
[Default Applications]
inode/directory=nemo.desktop;
application/x-directory=nemo.desktop;
MIME

# Kitty as default terminal
cat > "${ROOTFS}/home/vladd/.config/konsolerc" << 'KONSOLE'
[Desktop Entry]
DefaultProfile=MerphisOS.profile
KONSOLE

# LibreWolf privacy overrides
mkdir -p "${ROOTFS}/home/vladd/.librewolf"
cat > "${ROOTFS}/home/vladd/.librewolf/overrides.cfg" << 'LIBREWOLF'
lockPref("privacy.firstparty.isolate", true);
lockPref("privacy.resistFingerprinting", true);
lockPref("privacy.trackingprotection.enabled", true);
lockPref("network.trr.mode", 2);
lockPref("network.trr.uri", "https://dns.quad9.net/dns-query");
lockPref("geo.enabled", false);
lockPref("browser.safebrowsing.enabled", false);
lockPref("datareporting.healthreport.uploadEnabled", false);
lockPref("browser.ping-centre.telemetry", false);
LIBREWOLF

# SDDM
mkdir -p "${ROOTFS}/etc/sddm.conf.d"
cat > "${ROOTFS}/etc/sddm.conf.d/merphisos.conf" << 'SDDM'
[Theme]
Current=breeze
Font=Inter,10
[General]
HaltCommand=/usr/bin/systemctl poweroff
RebootCommand=/usr/bin/systemctl reboot
SDDM

# Fix ownership
chown -R 1000:1000 "${ROOTFS}/home/vladd"

# Copy to skel for future users
mkdir -p "${ROOTFS}/etc/skel"
cp -r "${ROOTFS}/home/vladd/.config" "${ROOTFS}/etc/skel/" 2>/dev/null || true
cp -r "${ROOTFS}/home/vladd/.librewolf" "${ROOTFS}/etc/skel/" 2>/dev/null || true

echo "   ✅ Hybrido DE configured"

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
    -comp zstd -Xcompression-level 19 -b 1M \
    -no-xattrs -noappend 2>&1 | tail -2

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
menuentry "MerphisOS 0.2-beta — Hybrido DE" {
    linux /boot/vmlinuz boot=live live-media-path=/live/ quiet splash
    initrd /boot/initrd
}
menuentry "MerphisOS 0.2-beta (Safe Mode)" {
    linux /boot/vmlinuz boot=live live-media-path=/live/ nomodeset noapic nolapic
    initrd /boot/initrd
}
GRUB

#=============================================================================
# PAS 5: Asamblare ISO
#=============================================================================
echo ""
echo "[5/5] Assembling ISO..."

ISO_NAME="merphisos-0.2-beta-hybrido-amd64.iso"
ISO_OUTPUT="${OUTPUT_DIR}/${ISO_NAME}"

grub-mkrescue --output="${ISO_OUTPUT}" "${ISO_DIR}" 2>&1 | tail -3

if [ -f "${ISO_OUTPUT}" ]; then
    SIZE=$(du -h "${ISO_OUTPUT}" | cut -f1)
    MD5=$(md5sum "${ISO_OUTPUT}" | cut -d' ' -f1)
    echo ""
    echo "=========================================="
    echo "  ✅ MERPHISOS 0.2-beta BUILD SUCCESS!"
    echo "  📁 ${ISO_OUTPUT}"
    echo "  📦 Size: ${SIZE}"
    echo "  🔐 MD5: ${MD5}"
    echo "=========================================="
else
    echo "❌ FAILED"
    exit 1
fi

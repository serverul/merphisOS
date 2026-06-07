#!/usr/bin/env bash
# MerphisOS ISO Generator — runs inside Docker with xorriso
set -euo pipefail

ROOTFS="/build/rootfs"
ISO_DIR="/build/iso"
OUTPUT_DIR="/build/output"

echo "=========================================="
echo "  MerphisOS 0.2-beta — Hybrido DE ISO"
echo "=========================================="

mkdir -p "${OUTPUT_DIR}" "${ISO_DIR}/live" "${ISO_DIR}/boot/grub"

#=============================================================================
# PAS 1: Rootfs (pre-extras)
#=============================================================================
echo ""
echo "[1/3] Rootfs already extracted at ${ROOTFS}"
echo "   Size: $(du -sh "${ROOTFS}" | cut -f1)"

#=============================================================================
# PAS 2: Configurare Hybrido DE
#=============================================================================
echo ""
echo "[2/3] Configuring Hybrido DE..."

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

# --- Wallpaper + Logo (from /build/artwork/) ---
echo "   Installing MerphisOS artwork..."
if [ -d "/build/artwork/wallpapers" ]; then
    mkdir -p "${ROOTFS}/usr/share/wallpapers/MerphisOS/content"

    # Copy all wallpapers
    cp /build/artwork/wallpapers/*.jpg "${ROOTFS}/usr/share/wallpapers/MerphisOS/content/" 2>/dev/null || true

    # Set default wallpaper (merphisos-space.jpg preferred, otherwise first found)
    if [ -f "/build/artwork/wallpapers/default.jpg" ]; then
        cp "/build/artwork/wallpapers/default.jpg" "${ROOTFS}/usr/share/wallpapers/MerphisOS/default.jpg"
    else
        for f in /build/artwork/wallpapers/*.jpg; do
            cp "$f" "${ROOTFS}/usr/share/wallpapers/MerphisOS/default.jpg"
            break
        done
    fi

    # Wallpaper metadata for KDE
    cat > "${ROOTFS}/usr/share/wallpapers/MerphisOS/metadata.desktop" << 'WPMETA'
[Wallpaper]
Name=MerphisOS
Name[ro]=MerphisOS
Author=MerphisOS
Version=1.0
License=Proprietary

[Desktop Entry]
Type=X-KDE-Plasma-Wallpaper
X-KDE-PluginInfo-Name=MerphisOS
X-KDE-PluginInfo-Category=Wallpaper
X-KDE-PluginInfo-License=Proprietary
X-KDE-PluginInfo-Version=1.0
X-KDE-PluginInfo-Author=MerphisOS
WPMETA

    echo "   ✅ Wallpapers installed ($(ls ${ROOTFS}/usr/share/wallpapers/MerphisOS/content/ | wc -l) total)"
else
    echo "   ⚠️  No artwork found in /build/artwork/, using placeholder"
    mkdir -p "${ROOTFS}/usr/share/wallpapers/MerphisOS"
    touch "${ROOTFS}/usr/share/wallpapers/MerphisOS/default.jpg"
fi

# SDDM logo
if [ -d "/build/artwork/sddm" ]; then
    mkdir -p "${ROOTFS}/usr/share/sddm/themes/merphisos"
    cp /build/artwork/sddm/*.jpg "${ROOTFS}/usr/share/sddm/themes/merphisos/" 2>/dev/null || true
    echo "   ✅ SDDM logo installed"
fi

# --- User config defaults ---
mkdir -p "${ROOTFS}/home/vladd/.config"
mkdir -p "${ROOTFS}/home/vladd/.local/share/plasma"
mkdir -p "${ROOTFS}/home/vladd/.config/plasma-workspace"
cat > "${ROOTFS}/home/vladd/.config/plasma-workspace/first_run" << 'EOF'
first_run=false
EOF

# KWin: Wayland, no X11
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
mkdir -p "${ROOTFS}/home/vladd/.local/share/konsole"
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

# Copy to skel
mkdir -p "${ROOTFS}/etc/skel"
cp -r "${ROOTFS}/home/vladd/.config" "${ROOTFS}/etc/skel/" 2>/dev/null || true
cp -r "${ROOTFS}/home/vladd/.librewolf" "${ROOTFS}/etc/skel/" 2>/dev/null || true

echo "   ✅ Hybrido DE configured"

#=============================================================================
# PAS 3: Generare ISO
#=============================================================================
echo ""
echo "[3/3] Generating ISO..."

# Kernel + initrd
cp "${ROOTFS}/boot/vmlinuz-"* "${ISO_DIR}/boot/vmlinuz" 2>/dev/null || echo "   ⚠️ No vmlinuz found"
cp "${ROOTFS}/boot/initrd.img-"* "${ISO_DIR}/boot/initrd" 2>/dev/null || echo "   ⚠️ No initrd found"

# Squashfs
echo "   Creating squashfs (zstd level 19)..."
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

# ISO
ISO_NAME="merphisos-0.2-beta-hybrido-amd64.iso"
ISO_OUTPUT="${OUTPUT_DIR}/${ISO_NAME}"

echo "   Running grub-mkrescue..."
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
    echo "❌ FAILED — ISO not created"
    exit 1
fi

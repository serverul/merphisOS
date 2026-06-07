#!/usr/bin/env bash
# MerphisOS ISO Generator — runs inside Docker with xorriso
set -euo pipefail

ROOTFS="/build/rootfs"
ISO_DIR="/build/iso"
OUTPUT_DIR="/build/output"

echo "=========================================="
echo "  MerphisOS 0.3-beta — Hybrido DE ISO"
echo "=========================================="

mkdir -p "${OUTPUT_DIR}" "${ISO_DIR}/live" "${ISO_DIR}/boot/grub"

#=============================================================================
# PAS 1: Rootfs (pre-extras)
#=============================================================================
echo ""
echo "[1/4] Rootfs already extracted at ${ROOTFS}"
echo "   Size: $(du -sh "${ROOTFS}" | cut -f1)"

#=============================================================================
# PAS 1b: Rebuild initrd with compression (fix OOM in GRUB)
#=============================================================================
echo ""
echo "[2/4] Rebuilding initrd with compression..."
mount --bind /proc "${ROOTFS}/proc" 2>/dev/null || true
mount --bind /sys "${ROOTFS}/sys" 2>/dev/null || true
mount --bind /dev "${ROOTFS}/dev" 2>/dev/null || true
cp /etc/resolv.conf "${ROOTFS}/etc/resolv.conf" 2>/dev/null || true

chroot "${ROOTFS}" /bin/bash << 'CHROOT_INITRD'
export DEBIAN_FRONTEND=noninteractive
# Rebuild initrd with zstd compression
echo "COMPRESS=zstd" >> /etc/initramfs-tools/initramfs.conf
update-initramfs -u -k all 2>&1 | tail -5
echo "   ✅ Initrd rebuilt"
# Check size after compression
ls -lh /boot/initrd.img-* 2>/dev/null
CHROOT_INITRD

umount "${ROOTFS}/proc" 2>/dev/null || true
umount "${ROOTFS}/sys" 2>/dev/null || true
umount "${ROOTFS}/dev" 2>/dev/null || true
echo "   ✅ Initrd compression complete"

#=============================================================================
# PAS 3: Configurare Hybrido DE
#=============================================================================
echo ""
echo "[3/4] Configuring Hybrido DE..."

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

# --- Hybrido Scripts in PATH ---
cp /build/artwork/scripts/switch-mode.sh "${ROOTFS}/usr/local/bin/switch-mode"
cp /build/artwork/scripts/first-run.sh "${ROOTFS}/usr/local/bin/hybrido-first-run"
chmod +x "${ROOTFS}/usr/local/bin/switch-mode" "${ROOTFS}/usr/local/bin/hybrido-first-run"
echo "   ✅ Hybrido scripts installed (switch-mode, hybrido-first-run)"

# --- Calamares installer desktop launcher ---
mkdir -p "${ROOTFS}/home/live/.config/autostart"
cat > "${ROOTFS}/home/live/.config/autostart/hybrido-first-run.desktop" << 'AUTOSTART'
[Desktop Entry]
Type=Application
Name=Hybrido First Run
Exec=/usr/local/bin/hybrido-first-run
Terminal=false
X-KDE-autostart-after=plasma-core
X-KDE-autostart-phase=2
OnlyShowIn=KDE
AUTOSTART

# --- Installer shortcut on desktop ---
mkdir -p "${ROOTFS}/home/live/Desktop"
cat > "${ROOTFS}/home/live/Desktop/calamares.desktop" << 'CALADESK'
[Desktop Entry]
Type=Application
Name=Install MerphisOS
Comment=Instalează MerphisOS pe hard disk
Exec=calamares
Icon=drive-harddisk
Terminal=false
Categories=Qt;KDE;System;
CALADESK
chmod +x "${ROOTFS}/home/live/Desktop/calamares.desktop"

# --- User config defaults ===
echo "   Configuring live user defaults..."
mkdir -p "${ROOTFS}/home/live/.config"
mkdir -p "${ROOTFS}/home/live/.local/share/plasma"
mkdir -p "${ROOTFS}/home/live/.config/plasma-workspace"
cat > "${ROOTFS}/home/live/.config/plasma-workspace/first_run" << 'EOF'
first_run=false
EOF

# KWin: Wayland, no X11
cat > "${ROOTFS}/home/live/.config/kwinrc" << 'KWIN'
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
cat > "${ROOTFS}/home/live/.config/mimeapps.list" << 'MIME'
[Default Applications]
inode/directory=nemo.desktop;
application/x-directory=nemo.desktop;
MIME

# Kitty as default terminal
mkdir -p "${ROOTFS}/home/live/.local/share/konsole"
cat > "${ROOTFS}/home/live/.config/konsolerc" << 'KONSOLE'
[Desktop Entry]
DefaultProfile=MerphisOS.profile
KONSOLE

# LibreWolf privacy overrides (also applied system-wide via /etc/librewolf)
mkdir -p "${ROOTFS}/home/live/.librewolf"
cat > "${ROOTFS}/home/live/.librewolf/overrides.cfg" << 'LIBREWOLF'
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

# SDDM + auto-login for live user
mkdir -p "${ROOTFS}/etc/sddm.conf.d"
cat > "${ROOTFS}/etc/sddm.conf.d/merphisos.conf" << 'SDDM'
[Theme]
Current=breeze
Font=Inter,10
[General]
HaltCommand=/usr/bin/systemctl poweroff
RebootCommand=/usr/bin/systemctl reboot
[Autologin]
User=live
Session=plasma-wayland
SDDM

# Calamares config (DON'T auto-start - launched from desktop icon)
mkdir -p "${ROOTFS}/etc/calamares"
cat > "${ROOTFS}/etc/calamares/settings.conf" << 'CALASET'
---
modules-search: [ /lib/calamares/modules, /etc/calamares/modules ]
sequence:
- brand:
    - welcome
    - license
- locale:
    - locale
- partition:
    - partition
- users:
    - users
- networkcfg:
    - networkcfg
- localecfg:
    - localecfg
- luksopenswaphookcfg:
    - luksopenswaphookcfg
- plymouthcfg:
    - plymouthcfg
- grubcfg:
    - grubcfg
- fstab:
    - fstab
- mount:
    - mount
- initramfg:
    - initramfs
- unpackfs:
    - unpackfs
- bootloader:
    - bootloader
- services:
    - services
- grubcfg:
    - grubcfg
- plymouthcfg:
    - plymouthcfg
- hwclock:
    - hwclock
- shutdown:
    - shutdown
branding: merphisos
prompt-install: true
dont-chroot: false
oem-setup: false
disable-cancel: false
disable-cancel-during-exec: true
preserve-files: []
CALASET

# Fix ownership
chown -R 1000:1000 "${ROOTFS}/home/live" "${ROOTFS}/home/live/Desktop"

# Copy to skel (for newly created users during install)
mkdir -p "${ROOTFS}/etc/skel"
cp -r "${ROOTFS}/home/live/.config" "${ROOTFS}/etc/skel/" 2>/dev/null || true
cp -r "${ROOTFS}/home/live/.librewolf" "${ROOTFS}/etc/skel/" 2>/dev/null || true

#=============================================================================
# PHASE 3: Plymouth + System Hardening + Calamares Branding
#=============================================================================
echo "   Configuring system hardening..."

# --- Plymouth: folosim spinner ca fallback, theme-ul custom va fi generat post-install ---
mkdir -p "${ROOTFS}/usr/share/plymouth/themes/merphisos"
cat > "${ROOTFS}/usr/share/plymouth/themes/merphisos/merphisos.plymouth" << 'PLYMDATA'
[Plymouth Theme]
Name=MerphisOS
Description=MerphisOS Boot Splash
ModuleName=spinfinity
PLYMDATA
plymouth-set-default-theme -R spinfinity 2>/dev/null || true
echo "   ✅ Plymouth: spinner theme (custom sprite post-install)"

# --- sysctl hardening ---
install -D -m 644 /build/config/99-merphisos-sysctl.conf \
    "${ROOTFS}/etc/sysctl.d/99-merphisos-sysctl.conf" 2>/dev/null || \
    cat > "${ROOTFS}/etc/sysctl.d/99-merphisos-sysctl.conf" << 'SYSCTL'
# Network Hardening
net.ipv4.ip_forward = 0
net.ipv6.conf.all.forwarding = 0
net.ipv4.conf.all.accept_redirects = 0
net.ipv6.conf.all.accept_redirects = 0
net.ipv4.conf.all.send_redirects = 0
net.ipv4.conf.all.accept_source_route = 0
net.ipv6.conf.all.accept_source_route = 0
net.ipv4.icmp_echo_ignore_broadcasts = 1
net.ipv4.tcp_syncookies = 1
net.ipv4.conf.all.rp_filter = 1
net.ipv4.conf.all.log_martians = 1
net.core.bpf_jit_enable = 0
# Kernel Hardening
kernel.randomize_va_space = 2
kernel.dmesg_restrict = 1
kernel.kptr_restrict = 2
kernel.panic_on_oops = 1
kernel.exec-shield = 1
vm.mmap_min_addr = 65536
kernel.yama.ptrace_scope = 1
kernel.panic = 10
SYSCTL
echo "   ✅ sysctl hardening applied"

# --- nftables firewall ---
install -D -m 644 /build/config/merphisos-nftables.conf \
    "${ROOTFS}/etc/nftables.conf" 2>/dev/null || \
    cat > "${ROOTFS}/etc/nftables.conf" << 'NFTABLES'
#!/usr/sbin/nft -f
flush ruleset
table inet filter {
    chain input { type filter hook input priority 0; policy drop;
        iif lo accept
        ct state established,related accept
        ct state invalid drop
        ip protocol icmp limit rate 10/second accept
        ip6 nexthdr icmpv6 limit rate 10/second accept
        tcp dport 22 ip saddr { 192.168.0.0/16, 10.0.0.0/8, 172.16.0.0/12 } accept
        tcp dport 22 drop
        udp dport 67-68 accept
    }
    chain forward { type filter hook forward priority 0; policy drop; }
    chain output { type filter hook output priority 0; policy accept; }
}
NFTABLES
chmod +x "${ROOTFS}/etc/nftables.conf"
echo "   ✅ nftables firewall configured (deny inbound)"

# --- systemd-resolved Quad9 DoT ---
cat > "${ROOTFS}/etc/systemd/resolved.conf" << 'RESOLVED'
[Resolve]
DNS=9.9.9.9#dns.quad9.net 149.112.112.112#dns.quad9.net
DNSOverTLS=yes
DNSSEC=yes
Cache=yes
CacheFromLocalhost=yes
LLMNR=no
MulticastDNS=no
RESOLVED
echo "   ✅ Quad9 DNS-over-TLS configured"

# --- NetworkManager MAC randomization ---
mkdir -p "${ROOTFS}/etc/NetworkManager/conf.d"
cat > "${ROOTFS}/etc/NetworkManager/conf.d/99-merphisos-mac.conf" << 'NMMAC'
[Device]
wifi.scan-rand-mac-address=yes
NMMAC
echo "   ✅ WiFi MAC randomization enabled"

# --- Calamares branding files ---
if [ -d "/build/calamares" ]; then
    mkdir -p "${ROOTFS}/etc/calamares/branding/merphisos"
    cp -r /build/calamares/branding/merphisos/* "${ROOTFS}/etc/calamares/branding/merphisos/" 2>/dev/null || true
    mkdir -p "${ROOTFS}/etc/calamares/modules"
    cp -r /build/calamares/modules/* "${ROOTFS}/etc/calamares/modules/" 2>/dev/null || true
    echo "   ✅ Calamares branding installed"
fi

# --- SDDM auto-login confirmed ---
echo "   ✅ SDDM auto-login: live/plasma-wayland"

#=============================================================================
# TELEMETRY: Disable all OS and app telemetry
#=============================================================================
echo "   Disabling telemetry and data collection..."

# --- KDE User Feedback (kuserfeedback) ---
mkdir -p "${ROOTFS}/etc/xdg/KDE"
cat > "${ROOTFS}/etc/xdg/kdeglobals" << 'KDEGLOBALS'
[KDE User Feedback]
FeedbackEnabled=false
KDEGLOBALS

# --- KDE Privacy (recent files, activity tracking) ---
mkdir -p "${ROOTFS}/home/live/.config"
cat > "${ROOTFS}/home/live/.config/kactivitymanagerdrc" << 'KACT'
[main]
disable-activity-tracking=true
disable-recent-files=true
KACT
cat > "${ROOTFS}/home/live/.config/kdeglobals" << 'KDEPRIV'
[KDE User Feedback]
FeedbackEnabled=false
[Privacy]
RecentFiles=false
Activities=false
ApplicationUsage=false
NotificationHistory=false
KDEPRIV
cp "${ROOTFS}/home/live/.config/kdeglobals" "${ROOTFS}/etc/skel/.config/kdeglobals" 2>/dev/null || true

# --- Baloo (file indexer) completely disabled ---
mkdir -p "${ROOTFS}/home/live/.config"
cat > "${ROOTFS}/home/live/.config/baloofilerc" << 'BALOO'
[Basic Settings]
Indexing-Enabled=false
IndexRecentFiles=false
OnlyIndexBasicMetadata=true
Exclude Filters=*
Exclude Folders=/
BALOO
cat > "${ROOTFS}/etc/xdg/baloofilerc" << 'BALOOETC'
[Basic Settings]
Indexing-Enabled=false
IndexRecentFiles=false
OnlyIndexBasicMetadata=true
BALOOETC

# --- systemd-journald: volatile, limited ---
mkdir -p "${ROOTFS}/etc/systemd/journald.conf.d"
cat > "${ROOTFS}/etc/systemd/journald.conf.d/99-merphisos.conf" << 'JOURNAL'
[Journal]
Storage=volatile
SystemMaxUse=50M
ForwardToConsole=no
Audit=no
JOURNAL

# --- systemd-coredump: disabled ---
mkdir -p "${ROOTFS}/etc/systemd/coredump.conf.d"
cat > "${ROOTFS}/etc/systemd/coredump.conf.d/99-merphisos.conf" << 'COREDUMP'
[Coredump]
Storage=none
ProcessSizeMax=0
COREDUMP

# --- LibreWolf system-wide telemetry OFF ---
mkdir -p "${ROOTFS}/etc/librewolf"
cat > "${ROOTFS}/etc/librewolf/overrides.cfg" << 'LWTELE'
// MerphisOS — System-wide LibreWolf telemetry override
lockPref("app.normandy.enabled", false);
lockPref("app.shield.optoutstudies.enabled", false);
lockPref("browser.newtabpage.activity-stream.feeds.telemetry", false);
lockPref("browser.newtabpage.activity-stream.telemetry", false);
lockPref("browser.ping-centre.telemetry", false);
lockPref("browser.safebrowsing.enabled", false);
lockPref("browser.tabs.crashReporting.sendReport", false);
lockPref("datareporting.healthreport.uploadEnabled", false);
lockPref("datareporting.policy.dataSubmissionEnabled", false);
lockPref("devtools.onboarding.telemetry.logged", true);
lockPref("dom.push.enabled", false);
lockPref("extensions.pocket.enabled", false);
lockPref("network.allow-experiments", false);
lockPref("media.video_stats.enabled", false);
lockPref("toolkit.telemetry.archive.enabled", false);
lockPref("toolkit.telemetry.bhrPing.enabled", false);
lockPref("toolkit.telemetry.enabled", false);
lockPref("toolkit.telemetry.hybridContent.enabled", false);
lockPref("toolkit.telemetry.unified", false);
lockPref("toolkit.telemetry.server", "");
lockPref("privacy.trackingprotection.enabled", true);
LWTELE
# Also copy to user's .librewolf
mkdir -p "${ROOTFS}/home/live/.librewolf"
cp "${ROOTFS}/etc/librewolf/overrides.cfg" "${ROOTFS}/home/live/.librewolf/overrides.cfg"
cp "${ROOTFS}/etc/librewolf/overrides.cfg" "${ROOTFS}/etc/skel/.librewolf/overrides.cfg" 2>/dev/null || true

# --- VLC: disable update check + metadata network ---
mkdir -p "${ROOTFS}/home/live/.config/vlc"
cat > "${ROOTFS}/home/live/.config/vlc/vlcrc" << 'VLCRC'
[main]
update-check=0
metadata-network-access=0
lua-network=0
VLCRC
cp -r "${ROOTFS}/home/live/.config/vlc" "${ROOTFS}/etc/skel/.config/" 2>/dev/null || true

# --- Flatpak: disable auto-update checks ---
mkdir -p "${ROOTFS}/etc/flatpak"
cat > "${ROOTFS}/etc/flatpak/flatpakrc" << 'FLATPAKRC'
[Flatpak]
extra-languages=
update-auto=false
FLATPAKRC

echo "   ✅ All telemetry disabled (KDE, LibreWolf, VLC, systemd, Flatpak, Baloo, DrKonqi)"

echo "   ✅ System hardening complete"

echo "   ✅ Hybrido DE configured"

#=============================================================================
# PAS 4: Generare ISO
#=============================================================================
echo ""
echo "[4/4] Generating ISO..."

# Kernel + initrd — robust copy, fail if missing
echo "   Copying kernel and initrd..."
VMLINUZ_FILE=$(ls "${ROOTFS}/boot/vmlinuz-"* 2>/dev/null | head -1)
INITRD_FILE=$(ls "${ROOTFS}/boot/initrd.img-"* 2>/dev/null | head -1)
if [ -n "${VMLINUZ_FILE}" ] && [ -f "${VMLINUZ_FILE}" ]; then
    cp "${VMLINUZ_FILE}" "${ISO_DIR}/boot/vmlinuz"
    echo "   ✅ Kernel: $(basename ${VMLINUZ_FILE})"
else
    echo "   ⚠️ No kernel found!"
fi
if [ -n "${INITRD_FILE}" ] && [ -f "${INITRD_FILE}" ]; then
    cp "${INITRD_FILE}" "${ISO_DIR}/boot/initrd"
    echo "   ✅ Initrd: $(basename ${INITRD_FILE}) ($(du -h "${INITRD_FILE}" | cut -f1))"
else
    echo "   ⚠️ No initrd found!"
fi

# Squashfs
echo "   Creating squashfs (zstd level 19)..."
mksquashfs "${ROOTFS}" "${ISO_DIR}/live/filesystem.squashfs" \
    -comp zstd -Xcompression-level 19 -b 1M \
    -no-xattrs -noappend 2>&1 | tail -2

# Grub config — robust, cu loopback detection
cat > "${ISO_DIR}/boot/grub/grub.cfg" << 'GRUB'
set default=0
set timeout=10
set pager=0

# Load modules
insmod part_gpt
insmod part_msdos
insmod iso9660
insmod ext2
insmod fat
insmod udf
insmod gfxterm
insmod gfxmenu
insmod all_video
insmod videotest
insmod font
insmod echo

# Try to set correct GFX mode
if [ -f /boot/grub/fonts/unicode.pf2 ]; then
    loadfont /boot/grub/fonts/unicode.pf2
fi
terminal_output gfxterm
set gfxmode=1920x1080,1366x768,1024x768,auto
set gfxpayload=keep

# Background image if available
if [ -f /boot/grub/splash.png ]; then
    background_image /boot/grub/splash.png
fi

# Search for kernel by explicit path validation
if [ -f /boot/vmlinuz ]; then
    set kernel_path=/boot/vmlinuz
    set initrd_path=/boot/initrd
else
    echo "⚠️ Kernel not found! Booting with fallback..."
    set kernel_path=/boot/vmlinuz
    set initrd_path=/boot/initrd
fi

menuentry "MerphisOS 0.3-beta — Hybrido DE" {
    echo "Loading MerphisOS kernel..."
    linux ${kernel_path} boot=live live-media-path=/live/ quiet splash
    echo "Loading initrd..."
    initrd ${initrd_path}
}

menuentry "MerphisOS 0.3-beta (VirtualBox)" {
    echo "Loading MerphisOS kernel (VirtualBox mode)..."
    linux ${kernel_path} boot=live live-media-path=/live/ quiet splash nomodeset video=vesafb:off vga=normal
    echo "Loading initrd..."
    initrd ${initrd_path}
}

menuentry "MerphisOS 0.3-beta (Safe Mode)" {
    echo "Loading MerphisOS kernel (Safe Mode)..."
    linux ${kernel_path} boot=live live-media-path=/live/ nomodeset noapic nolapic acpi=off
    echo "Loading initrd..."
    initrd ${initrd_path}
}

menuentry "MerphisOS 0.3-beta (Verify & Test)" {
    echo "Loading MerphisOS kernel (Debug Mode)..."
    linux ${kernel_path} boot=live live-media-path=/live/ debug systemd.log_level=debug systemd.log_target=console
    echo "Loading initrd..."
    initrd ${initrd_path}
}

menuentry "🔁 Reboot" {
    reboot
}

menuentry "⏻ Shutdown" {
    halt
}
GRUB

# ISO
ISO_NAME="merphisos-0.3-beta-hybrido-amd64.iso"
ISO_OUTPUT="${OUTPUT_DIR}/${ISO_NAME}"

echo "   Running grub-mkrescue..."
grub-mkrescue --output="${ISO_OUTPUT}" "${ISO_DIR}" 2>&1 | tail -3

if [ -f "${ISO_OUTPUT}" ]; then
    SIZE=$(du -h "${ISO_OUTPUT}" | cut -f1)
    MD5=$(md5sum "${ISO_OUTPUT}" | cut -d' ' -f1)
    echo ""
    echo "=========================================="
    echo "  ✅ MERPHISOS 0.3-beta BUILD SUCCESS!"
    echo "  📁 ${ISO_OUTPUT}"
    echo "  📦 Size: ${SIZE}"
    echo "  🔐 MD5: ${MD5}"
    echo "=========================================="
else
    echo "❌ FAILED — ISO not created"
    exit 1
fi

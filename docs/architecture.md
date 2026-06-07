# MerphisOS 0.3.1-beta — Arhitectura Sistemului

> O privire de ansamblu asupra modului în care funcționează MerphisOS.

---

## 1. Stiva de Bază

```
┌──────────────────────────────────────────────────────────────┐
│                     HYBRIDO DESKTOP                          │
│  (Plasma 6 + KWin + custom themes + Nemo + apps)            │
├──────────────────────────────────────────────────────────────┤
│                      FLATPAK + DISTROBOX                     │
│  (aplicații sandboxed și containere CLI)                     │
├──────────────────────────────────────────────────────────────┤
│                   MERPHISOS PACKAGES (.deb)                  │
│  (kernel custom, teme, scripts, configurări)                │
├──────────────────────────────────────────────────────────────┤
│                    DEBIAN 13 TRIXIE BASE                     │
│  (sistem de pachete, biblioteci, toolchain)                 │
├──────────────────────────────────────────────────────────────┤
│                   KERNEL (linux-image-amd64)                  │
│  (stock Debian 6.12.90, zstd compressed, relocatable)       │
├──────────────────────────────────────────────────────────────┤
│          HARDWARE (laptop / workstation x86_64)             │
└──────────────────────────────────────────────────────────────┘
```

## 2. Boot Flow (ISO Live)

```
Power On
   ↓
UEFI Firmware
   ↓
GRUB (grub-mkrescue)
   ├── MerphisOS (default)
   │   ├── VirtualBox (nomodeset)
   │   ├── Safe Mode (noapic nolapic acpi=off)
   │   └── Verify & Test (debug logs)
   ├── Reboot
   └── Shutdown
   ↓ (select MerphisOS)
Kernel 6.12.90 (boot=live)
   ↓
initrd (live-boot)
   ↓
mount squashfs (/live/filesystem.squashfs)
   ↓
systemd (PID 1)
   ├── systemd-resolved (Quad9 DoT)
   ├── systemd-udevd (hardware)
   ├── systemd-logind (sessions)
   ├── NetworkManager
   ├── firewall (nftables)
   └── AppArmor
   ↓
SDDM (auto-login: live/merphisos)
   ↓
Plasma 6 + KWin Wayland
   ↓
hybrido-first-run (Baloo OFF, telemetry OFF, theme setup)
   ↓
Desktop ready
```

### Boot Flow (Instalat pe disc — via Calamares)

```
Power On → UEFI → GRUB → Kernel → systemd → SDDM → Plasma 6 → Desktop
```

## 3. Network Stack

```
User Space
├── Browser (LibreWolf) → Quad9 DoH via librewolf config
├── Apps → system DNS
├── systemd-resolved → DNS-over-TLS → Quad9 (9.9.9.9)
│   └── DNSSEC validation enabled
└── firewall (nftables) → DROP inbound, allow established

Kernel Space
├── nftables (firewall — deny inbound)
└── NetworkManager (WiFi/Ethernet — MAC randomizare)

Hardware
├── WiFi: MAC randomizat la scanare
└── Ethernet: standard DHCP
```

## 4. Container Strategy

```
MerphisOS Host
└── Flatpak (GUI apps sandboxed)
    ├── Flathub pre-configurat (auto-update OFF)
    └── Instalezi tu aplicațiile de care ai nevoie
```

## 5. Security Architecture

```
Layer 1: Hardware
├── Secure Boot (UEFI)
├── TPM (disk encryption key)
└── IOMMU (device isolation)

Layer 2: Kernel
├── Module signing (only signed modules)
├── Lockdown LSM (confidentiality mode)
├── Kernel ASLR
├── Stack canary
└── DMA-API strict

Layer 3: System
├── systemd (sandboxed services prin unit file directives)
├── AppArmor (MAC — Mandatory Access Control)
├── nftables (firewall)
├── systemd-resolved (DNS-over-TLS)
└── MAC randomization (WiFi)

Layer 4: Desktop
├── Flatpak sandbox (Bubblewrap namespaces)
├── Wayland (no keylogging, no screenshot)
├── LibreWolf (privacy.maximum)
└── Browser isolation (containers / separate profiles)

Layer 5: Network
├── VPN (Mullvad, WireGuard)
├── DNS (Quad9, encrypted)
├── Firewall (default deny inbound)
└── Kill switch (VPN required for sensitive traffic)
```

# MerphisOS — Arhitectura Sistemului

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
│                   CUSTOM KERNEL (HARDENED)                   │
│  (latest stable + module signing + lockdown + ASLR)         │
├──────────────────────────────────────────────────────────────┤
│          HARDWARE (laptop / workstation x86_64)             │
└──────────────────────────────────────────────────────────────┘
```

## 2. Boot Flow

```
Power On
   ↓
UEFI Firmware
   ↓
systemd-boot (bootloader)
   ├── Kernel MerphisOS (semnat, verified)
   │   ↓
   │   systemd (PID 1)
   │   ├── systemd-resolved (DNS)
   │   ├── systemd-udevd (hardware)
   │   ├── systemd-logind (sessions)
   │   ├── NetworkManager
   │   ├── firewall (nftables)
   │   ├── AppArmor (profiles)
   │   └── ... alte servicii
   │   ↓
   │   SDDM (login manager)
   │   ↓
   │   Plasma 6 + KWin (Wayland)
   │   ↓
   │   Hybrido DE (tema + panel + apps)
   │   ↓
   │   Welcome / First Run
   └──
   └── (opțional) boot alternativ:
       ├── Memtest86
       └── Recovery mode
```

## 3. Network Stack

```
User Space
├── Browser (LibreWolf) → DNS-over-HTTPS → Cloudflare/Quad9
├── Apps (Flatpak) → sandboxed network
├── CLI (Distrobox) → container network namespace
├── VPN (Mullvad) → WireGuard → kill switch
└── systemd-resolved → DNS-over-TLS → Quad9

Kernel Space
├── nftables (firewall)
├── NetworkManager (WiFi/Ethernet)
└── WireGuard (VPN interface)

Hardware
├── WiFi: Intel AXxxx (MAC randomizat)
└── Ethernet: Realtek/Intel (gigabit)
```

## 4. Container Strategy

```
MerphisOS Host
├── Flatpak (GUI apps)
│   ├── Mullvad Browser
│   ├── Stremio
│   └── VSCodium
│
├── Distrobox (CLI containers)
│   ├── Debian container (dev tools)
│   ├── Fedora container (testing)
│   └── Arch container (AUR packages)
│
└── Podman (service containers)
    ├── Vaultwarden
    ├── Nginx/Caddy
    ├── AdGuard Home
    └── ... orice self-hosted
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

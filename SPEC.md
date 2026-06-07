# MerphisOS — SPECIFICATION v0.3.1

> **Filosofie:** Your system, your rules.  
> **Target:** Laptop / workstation personal  
> **Bază:** Debian 13 "Trixie" (august 2025)

---

## Cuprins

1. [Viziune](#1-viziune)
2. [Arhitectura Sistemului](#2-arhitectura-sistemului)
3. [Kernel](#3-kernel)
4. [Hybrido Desktop Environment](#4-hybrido-desktop-environment)
5. [Aplicații Implicite](#5-aplicații-implicite)
6. [Confidențialitate și Securitate](#6-confidențialitate-și-securitate)
7. [Build System](#7-build-system)
8. [Ciclu de Lansare](#8-ciclu-de-lansare)
9. [Hardware Țintit](#9-hardware-țintit)
10. [Gestionarea Pachetelor](#10-gestionarea-pachetelor)
11. [Arhitectura Repo-ului](#11-arhitectura-repo-ului)

---

## 1. Viziune

MerphisOS este un sistem de operare Linux **privacy-first, securizat și frumos**,
construit pentru oameni care își găzduiesc singuri serviciile, care prețuiesc
confidențialitatea și care nu vor să facă compromisuri între estetică și
funcționalitate.

| Principiu | Descriere |
|---|---|
| **Privacy by design** | Zero telemetry. Zero phoning home. Totul opt-in. |
| **Security hardened** | Kernel custom cu hardening, AppArmor, firewall, semnare module. |
| **Beautiful by default** | Hybrido DE — un mediu desktop care arată și se simte ca macOS și Windows, la alegere. |
| **Container-native** | Flatpak pentru GUI, Distrobox pentru CLI. Nu poluăm sistemul de bază. |
| **Self-hosting ready** | Vaultwarden, servicii Docker, VPN — totul pre-configurat. |

### Public țintă

- Vlad (tu) și oameni ca tine: developeri, self-hosters, privacy-aware
- Foști utilizatori Windows/macOS care vor tranziție lină
- Oricine vrea un Linux care **funcționează din prima** fără să sacrifice controlul

---

## 2. Arhitectura Sistemului

```
┌─────────────────────────────────────────────────────────┐
│                     HARDWARE                              │
│  (laptop/workstation x86_64 — Intel/AMD/NVIDIA/...)     │
├─────────────────────────────────────────────────────────┤
│              KERNEL (latest vanilla + hardening)         │
│  ─ module signing, lockdown LSM, stackprotector, KASLR  │
│  ─ doar driverele necesare (atașăm suprafața de atac)   │
├─────────────────────────────────────────────────────────┤
│                 INIT: systemd (PID 1)                    │
│  ─ machined, nspawn, resolved, timerd, socket activation│
├─────────────────────────────────────────────────────────┤
│             USERLAND: Debian 13 Trixie                   │
│  ─ minim de pachete pre-instalate                       │
│  ─ totul semnat GPG                                     │
│  ─ repo nostru de pachete (.deb)                        │
├─────────────────────────────────────────────────────────┤
│         HYBRIDO DESKTOP ENVIRONMENT                      │
│  ─ bază: Plasma 6 (KWin + Wayland)                      │
│  ─ temă globală custom + panel-uri hibride              │
│  ─ toggle macOS / Windows layout                        │
│  ─ Nemo (file manager) în loc de Dolphin                │
├─────────────────────────────────────────────────────────┤
│              APPS (Flatpak + native)                     │
│  ─ LibreWolf / Mullvad Browser                          │
│  ─ VLC, Stremio                                         │
│  ─ Bitwarden, Mullvad VPN                               │
│  ─ Dev tools (Git, Python, Node, GCC, Podman)           │
├─────────────────────────────────────────────────────────┤
│              SECURITY LAYER                              │
│  ─ firewall nftables (default drop inbound)              │
│  ─ DNS-over-HTTPS (Quad9 / self-hosted)                 │
│  ─ AppArmor profiles                                    │
│  ─ MAC randomization WiFi                               │
│  ─ no connectivity check, no telemetry                  │
└─────────────────────────────────────────────────────────┘
```

### Decizii Arhitecturale Fundamentale

| Decizie | Opțiunea A | Opțiunea B | Aleasă | Motiv |
|---|---|---|---|---|
| Init system | systemd | OpenRC | **systemd** | systemd-nspawn, socket activation, compatibilitate |
| Display server | Wayland | Xorg | **Wayland** | Securitate, multi-monitor, HiDPI |
| DE approach | Construim de la zero | Modificăm DE existent | **Modificăm** | 3+ ani vs luni |
| DE bază | Plasma 6 | Budgie / Cinnamon | **Plasma 6** | Cel mai personalizabil, Wayland nativ, Qt6 |
| File manager | Dolphin (KDE) | Nemo | **Nemo** | Mai ușor, mai modern, mai configurabil |
| Package format | .deb (nativ) + Flatpak | RPM + Flatpak | **.deb + Flatpak** | Debian-based, ecosistem vast |
| Container runtime | Docker | Podman | **Podman** | Rootless by default, daemonless |
| CLI tools in containers | Distrobox | Toolbox | **Distrobox** | Mai flexibil, suportă orice imagine |

---

## 3. Kernel

### Sursa

- **Linux kernel vanilla** — ultimul stable disponibil pe kernel.org
- Tracking upstream la fiecare release minor (X.Y.Z)
- **Nu** folosim kernelul din Debian — îl compilăm noi

### Configurare Hardening

```
CONFIG_STATIC_USERMODEHELPER=y        # Previne hijacking-ul de helper
CONFIG_SECURITY_HARDENED_USERCOPY=y   # Copii sigure user/kernel
CONFIG_SCHED_STACK_END_CHECK=y        # Detectare stack overflow
CONFIG_STACKPROTECTOR_STRONG=y        # Protecție stack canary
CONFIG_RANDOMIZE_KSTACK_OFFSET=y      # Randomizare stack kernel
CONFIG_SECURITY_LOCKDOWN_LSM=y        # Lockdown LSM
CONFIG_LOCKDOWN_KERNEL_FORCE_CONFIDENTIALITY=y  # Maxim
CONFIG_MODULE_SIG=y                   # Semnare module
CONFIG_MODULE_SIG_FORCE=y             # Fără module nesemnate
CONFIG_MODULE_SIG_SHA512=y            # SHA-512 pentru semnături
CONFIG_IOMMU_DEFAULT_DMA_STRICT=y     # DMA strict prin IOMMU
CONFIG_SECURITY_SELINUX=y             # SELinux (optional)
CONFIG_SECURITY_APPARMOR=y            # AppArmor (default)
CONFIG_SYSTEM_TRUSTED_KEYS=...        # Doar cheile noastre
CONFIG_DEBUG_FS=n                     # Fără debugfs
CONFIG_KASAN=n                        # Nu în producție
CONFIG_STACK_VALIDATION=y             # Validare stivă
CONFIG_GCC_PLUGINS=y                  # Pluginuri GCC securitate
```

### Module Pruning

Compilăm doar driverele necesare pentru hardware-ul țintit:

- **CPU**: amd64 (Intel + AMD, microcode separat)
- **GPU**: Intel + AMD + NVIDIA (open + proprietary module la alegere)
- **WiFi**: Intel, MediaTek, Atheros, Broadcom (common laptop chips)
- **Bluetooth**: standard
- **Storage**: NVMe, SATA AHCI
- **Audio**: ALSA + PipeWire (nu OSS, nu alte interfețe vechi)
- **Networking**: wired gigabit, USB tethering
- **Input**: standard HID, touchpad multi-touch, touchscreen

Drivere **NEcompilate**: SCSI vechi, floppy, paralele port, token ring, ISDN, etc.

### File de Configurare

- `kernel/config/merphisos-hardened.config` — configurația completă
- `kernel/config/merphisos-modules.list` — lista modulelor incluse
- `kernel/patches/*.patch` — patch-uri custom (dacă e nevoie)

---

## 4. Hybrido Desktop Environment

### Concept

Hybrido este un mediu desktop **hibrid** care poate arăta și funcționa ca
**macOS** sau **Windows**, la alegerea utilizatorului, printr-un simplu toggle
în setări.

### Arhitectură

```
Hybrido DE
├── Compositor + WM: KWin (Plasma 6, Wayland)
├── Panels: Plasma Shell cu layout-uri custom
│   ├── macOS mode: floating top bar (global menu, app name, clock, widgets)
│   └── Windows mode: bottom taskbar (start button, pinned apps, tray)
├── App Launcher: Kickoff customizat (sau launcher propriu în viitor)
├── Window Decorations: Hybrido-MacOS, Hybrido-Windows
├── File Manager: Nemo + Nemo plugins
└── System Settings: Plasma System Settings + panou Hybrido
```

### Modul macOS

- **Panel**: sus, floating (transparent, cu blur), iconițe în stânga + centru
- **Global Menu**: meniul aplicației active în panelul de sus (ca macOS)
- **App Launcher**: Launchpad-style (grid de iconițe mari)
- **Window Controls**: în stânga (⬤⬤⬤ — închide, minimizează, maximizează — ca macOS)
- **Dock**: opțional, un dock în partea de jos (Plank / Latte Dock 2.0 / custom)
- **Spaces**: workspace-uri cu tranziții macOS-style
- **Top bar**: nume aplicație, ceas, baterie, WiFi, volum, centro de control

### Modul Windows

- **Panel**: jos, fix, cu buton de Start, aplicații pinuite, system tray
- **Start Menu**: clasic Windows-style (lista aplicații + pinned + recomandate)
- **Window Controls**: în dreapta (⬤⬤⬤ — minimizează, maximizează, închide)
- **Taskbar**: butoane cu text + icon (grupare opțională)
- **Action Center**: notificări plus quick settings (ca Windows 11)
- **Snap Assist**: split screen cu ghidaje vizuale (KWin le suportă nativ)

### Tema Unificată

- **Culoare accent**: dinamică (poate extrage dominantă din wallpaper — ca Windows/macOS)
- **Dark mode / Light mode**: global toggle
- **Material**: blur, transparență, colțuri rotunjite (consistente între moduri)
- **Font**: Inter sau SF Pro (alternative open-source)
- **Iconițe**: Tela Circle (custom palette) sau propriul set Hybrido

### Aplicații Default

| Rol | Aplicația | Înlocuiește |
|---|---|---|
| File manager | **Nemo** | Dolphin (greoi, urat, outdated) |
| Image viewer | **gThumb** sau **Nomacs** | Gwenview (opțional) |
| Text editor | **Kate** (Vim mode default) | KWrite |
| Terminal | **Kitty** | Konsole |
| Screenshot | **Spectacle** (se păstrează) | — |
| Settings | **Plasma System Settings** | — |

### Arhitectura Fișierelor

```
hybrido/
├── themes/
│   ├── hybrido-macos/              # Plasma theme: macOS mode
│   │   ├── colors
│   │   ├── decorations/
│   │   ├── plasma/
│   │   └── wallpaper/
│   └── hybrido-windows/            # Plasma theme: Windows mode
│       ├── colors
│       ├── decorations/
│       ├── plasma/
│       └── wallpaper/
├── panel-layouts/
│   ├── macos.layout.js             # Layout Plasma panel: macOS
│   └── windows.layout.js           # Layout Plasma panel: Windows
├── app-launcher/
│   └── (custom kickoff / own launcher when we build it)
└── scripts/
    ├── switch-mode.sh              # Comută între macOS și Windows
    └── first-run.sh                # Configurare inițială
```

---

## 5. Aplicații Implicite

### Pre-instalate (ISO)

| Categorie | Aplicație | Sursa | Justificare |
|---|---|---|---|
| 🌐 Browser | **LibreWolf** | Native (.deb) | Privacy-first Firefox fork |
| 🌐 Browser | **Mullvad Browser** | Flatpak | Browser Tor-hardened fără rețea Tor |
| 📺 Media | **VLC** | Native | Cel mai bun player video |
| 📺 Media | **Stremio** | Flatpak | Streaming platform |
| 🔒 VPN | **Mullvad VPN** | Native | WireGuard-based, no-log |
| 🆔 Passwords | **Bitwarden** | Native + extensie | Vaultwarden-ready |
| 🖥️ Terminal | **Kitty** | Native | GPU-accelerat, ligaturi, splits |
| 🗂️ Files | **Nemo** | Native | Ușor, modern, extensibil |
| 📝 Editor | **Kate** | Native | Vim mode, IDE-light |
| 📷 Screenshot | **Spectacle** | Native (KDE) | Cel mai bun screenshot tool |
| 🐳 Containers | **Podman** | Native | Rootless, daemonless |
| 📦 Apps | **Flatpak + Flathub** | Native | Aplicații sandboxed |
| 📦 CLI | **Distrobox** | Native | Tool-uri CLI în containere |
| 🧰 Git | **Git** | Native | Evident |
| 🐍 Python | **Python 3** | Native | Dev |
| ⚡ Node.js | **Node.js (LTS)** | Native | Dev |
| 🛠️ GCC | **GCC** | Native | Compilare |
| 🐞 Debug | **GDB, strace, lsof** | Native | Debugging |

### Disponibile în Repo (nu în ISO, instalare cu un click)

| Aplicație | Motiv |
|---|---|
| Docker CE | Dacă preferi Docker în loc de Podman |
| VSCodium | VS Code fără telemetrie Microsoft |
| Thunderbird | Email client |
| OBS Studio | Screen recording / streaming |
| GIMP | Image editing |
| Inkscape | Vector graphics |
| Steam | Gaming |
| Discord / Element | Comunicare |
| KVM + virt-manager | Virtual machines |
| Syncthing | File sync |

### Îndepărtate din Plasma Default

- Dolphin → înlocuit cu Nemo
- KDE PIM (Akonadi, KMail, KOrganizer, KAddressBook, Akregator) — resurse grele, nefolosite
- KDE Games (KMines, KSudoku, etc.) — gunoi vizual
- Kontact — PIM aggregator
- KGet / KTorrent — downloacer/torrent manager generic (qBittorrent în Flatpak e opțiunea)
- Elisa (music player) — VLC face tot
- Haruna / Dragon Player — VLC face tot
- Discover (Plasma app store) — la discreție, poate fi util

---

## 6. Confidențialitate și Securitate

### Implicit (nu trebuie configurat)

```
✅ Zero telemetry — nicio aplicație nu sună acasă
✅ DNS-over-HTTPS (Quad9: 9.9.9.9) — fără DNS leaks
✅ MAC randomizare WiFi — automat la fiecare rețea nouă
✅ Firewall: nftables — inbound deny by default, outbound allow
✅ Timesyncd cu NTS (Network Time Security) — fără NTP vanilla
✅ NetworkManager — connectivity check DISABLED
✅ LibreWolf — privacy.maximum preset
✅ Mullvad VPN — pre-instalat, configurare gata
✅ AppArmor — profile active pentru toate aplicațiile pre-instalate
✅ Kernel lockdown — confidentiality mode
✅ Module kernel semnate — doar cele aprobate de noi
```

### Opt-in (configurabile în System Settings)

```
⏹️ Auditd — system call auditing (doar dacă vrei)
⏹️ SELinux — alături de AppArmor (pentru hardcore security)
⏹️ Firewall outbound restrictions — allowlist mode (doar ce aprobi)
⏹️ DNS-over-TLS în loc de DNS-over-HTTPS (preferință)
⏹️ Self-hosted DNS (Pi-hole / AdGuard Home) configurare ghidată
⏹️ Tor (prin Mullvad sau direct)
```

### Ce NU e în MerphisOS

```
❌ Snaps (Canonical, proprietary backend, forced updates)
❌ GNOME Online Accounts (Google/Microsoft/Nextcloud în Settings)
❌ Ubuntu Pro / Landscape (canal de telemetry)
❌ Connectivity check (http://connectivity-check/... — ăla de la Canonical)
❌ Pop!_Shop / Ubuntu Software + background snapd
❌ Systemd-resolved fără NTS (configurat corect din prima)
❌ Whoopsie (Ubuntu error reporting)
❌ Apport (automatic crash reports)
```

---

## 7. Build System

### Faza 1 — Bootstrap cu mkosi (2-3 săptămâni)

Scop: ISO bootabil minimal cu Debian Trixie + Plasma 6 + pachetele noastre.

```
1. mkosi -d debian -r trixie    # imagine de bază
2. Adăugăm pachetele noastre    # kernel custom, hybrido, apps
3. Configurăm systemd-firstboot # utilizator, hostname, locale
4. Generăm ISO cu grub-mkrescue
```

### Faza 2 — Pipeline propriu (lunile 2-6)

```
scripts/
├── build-kernel.sh      # Descarcă, patchează, compilează, semnează
├── build-base.sh        # debootstrap + configurează sistemul de bază
├── build-hybrido.sh     # Construiește pachetele Hybrido (.deb)
├── build-iso.sh         # xorriso + grub-mkrescue
├── sign.sh              # Semnează kernel, module, pachete
└── test.sh              # Testează în QEMU
```

### Semnare

- **Kernel**: semnat cu cheie GPG proprie
- **Module kernel**: semnate cu aceeași cheie
- **Pachete .deb**: semnate GPG, repo nostru cu Release.gpg
- **ISO**: checksum SHA-512 + semnătură GPG detached

### Build Requirements

- Mașină de build: minim 4 core, 8GB RAM, 50GB disk
- Pachete host: debootstrap, xorriso, grub-efi, mtools, dosfstools, sbsigntool
- Containerizat: ideal în Podman/Docker pentru reproducebility

---

## 8. Ciclu de Lansare

| Component | Ciclu | Update |
|---|---|---|
| **Kernel** | Tracking latest stable | La câteva zile/săptămâni după upstream |
| **Pachete sistem** | Debian Trixie stable | Security patches backport |
| **Pachete Hybrido** | La fiecare release MerphisOS | Major changes |
| **Flatpak apps** | Continuu | Flathub |
| **MerphisOS release** | La 12-18 luni | Coincide cu Debian point releases |
| **Security fixes** | 48h de la upstream | Patch imediat |

### Numerotare Versiuni

```
MerphisOS v1.0  — prima versiune stabilă
MerphisOS v1.1  — security + bug fixes
MerphisOS v2.0  — următorul release major
```

---

## 9. Hardware Țintit

### Target primar

- **Laptop**: ThinkPad X1 Carbon / T-series, Dell XPS, Framework, orice laptop x86_64
- **CPU**: Intel Core i5/i7/i9 12th gen+ sau AMD Ryzen 5/7/9
- **GPU**: Intel Arc / Iris Xe, AMD Radeon RX, NVIDIA GeForce RTX
- **RAM**: 8GB+
- **Storage**: NVMe SSD
- **WiFi**: Intel AXxxx, MediaTek MT79xx, Qualcomm QCNFA7xx
- **Display**: 1080p până la 4K, HiDPI support

### Target secundar

- **Desktop DIY** — orice placă de bază x86_64
- **Workstation** — multi-GPU, NVLink, Threadripper/Xeon

### Non-target (nu testăm activ)

- ARM (Raspberry Pi, Apple Silicon) — poate în viitor
- 32-bit — nu
- Server pur (fără GPU) — nu e focusul, dar merge

---

## 10. Gestionarea Pachetelor

### Surse

| Sursă | Conținut | Prioritate |
|---|---|---|
| **Debian Trixie (main)** | Sistemul de bază | 500 |
| **Debian Trixie (security)** | Patch-uri securitate | 100 |
| **MerphisOS (custom repo)** | Pachetele noastre (kernel, hybrido, scripts) | 900 |
| **Flathub** | Aplicații desktop sandboxed | N/A (Flatpak) |
| **Docker Hub / quay.io** | Imagini pentru Distrobox | N/A (Distrobox) |

### Repo Nostru

- Format: `.deb` standard
- Semnat GPG
- Găzduit: pe serverul tău (self-hosted, eventual pe același VPS cu Vaultwarden)
- Pachete minimale:
  - `merphisos-kernel` — kernelul custom
  - `merphisos-kernel-headers` — headere pentru compilat module externe
  - `merphisos-hybrido-theme` — temele Hybrido
  - `merphisos-hybrido-panels` — layout-urile de panel
  - `merphisos-hybrido-scripts` — scripturile de switch mode
  - `merphisos-default-settings` — configurațiile implicite
  - `merphisos-privacy` — reguli firewall, AppArmor, DNS
  - `merphisos-wallpapers` — wallpaper-uri oficiale

---

## 11. Arhitectura Repo-ului

```
merphisOS/
├── README.md                 # Prezentare generală
├── SPEC.md                   # Specificația completă (acest fișier)
├── ROADMAP.md                # Faze de dezvoltare
├── LICENSE                   # Licență (GPLv3 / MIT)
│
├── docs/
│   ├── architecture.md       # Arhitectură detaliată
│   ├── hybrido-design.md     # Design-ul Hybrido DE
│   ├── privacy-policy.md     # Politica de confidențialitate
│   └── decisions/
│       └── 001-systemd.md    # ADR: de ce systemd
│
├── kernel/
│   ├── config/
│   │   ├── merphisos-hardened.config   # Config kernel
│   │   └── merphisos-modules.list      # Module list
│   └── patches/
│       └── (patch-uri custom)
│
├── base/
│   ├── packages/
│   │   ├── core.list         # Pachete obligatorii
│   │   ├── desktop.list      # Pachete DE + apps
│   │   └── minimal.list      # Pentru varianta fără DE
│   └── scripts/
│       ├── build-kernel.sh
│       ├── build-base.sh
│       ├── chroot-config.sh
│       └── build-iso.sh
│
├── hybrido/
│   ├── themes/
│   │   ├── hybrido-macos/
│   │   └── hybrido-windows/
│   ├── panel-layouts/
│   │   ├── macos.layout.js
│   │   └── windows.layout.js
│   ├── app-launcher/
│   │   └── (viitor)
│   └── scripts/
│       ├── switch-mode.sh
│       └── first-run.sh
│
├── images/
│   └── (mockup-uri, screenshot-uri)
│
└── tools/
    ├── Dockerfile.build      # Build environment container
    └── test-in-qemu.sh       # Script de testare
```

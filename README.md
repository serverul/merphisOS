# MerphisOS v0.3.1-beta — Hybrido DE 🚀

> **Your system, your rules.**
>
> MerphisOS este un sistem de operare Linux **privacy-first, securizat și frumos**,
> construit pe **Debian 13 "Trixie"**, cu **Hybrido Desktop Environment** și
> **Plasma 6** pe **Wayland exclusiv** (zero X11).

---

## 📥 Download

⬇️ **https://github.com/serverul/merphisOS/releases/tag/v0.3.1-beta**

ISO: `merphisos-0.3.1-beta-hybrido-amd64.iso` (2.0 GB)
Login: **`live` / `merphisos`** (auto-login SDDM)

---

## ✨ Ce e nou în v0.3.1-beta

| Categorie | Componentă | Status |
|---|---|---|
| 🖥️ **Desktop** | Plasma 6.3.5 + KWin Wayland | ✅ |
| 🌐 **Browser** | LibreWolf 151 (privacy-first, system-wide telemetry OFF) | ✅ |
| 🗂️ **File Manager** | Nemo (înlocuiește Dolphin) | ✅ |
| 🖥️ **Terminal** | Kitty | ✅ |
| 📺 **Multimedia** | VLC 3.0.23 (telemetry OFF) | ✅ |
| 🎨 **Hybrido macOS Theme** | Top bar + butoane stânga + Global Menu | ✅ |
| 🎨 **Hybrido Windows Theme** | Taskbar jos + butoane dreapta | ✅ |
| 🔄 **switch-mode** | Comută între macOS / Windows instant | ✅ |
| 🚀 **first-run** | Script inițial la prima autentificare | ✅ |
| 🔒 **Firewall** | nftables (deny inbound, allow established + SSH LAN) | ✅ |
| 🔐 **DNS** | Quad9 DNS-over-TLS + DNSSEC | ✅ |
| 📡 **WiFi** | MAC randomizare la scanare | ✅ |
| ⚙️ **Kernel hardening** | ASLR, kptr_restrict, dmesg_restrict, ptrace_scope, panic | ✅ |
| 🛡️ **AppArmor** | Profiluri implicite active | ✅ |
| 🚫 **Telemetrie** | KDE feedback, Baloo, recent files, LibreWolf, VLC, DrKonqi, systemd coredump | ✅ |
| 📦 **Flatpak** | Flathub pre-configurat (auto-update OFF) | ✅ |
| 💾 **Instalator** | Calamares cu branding MerphisOS | ✅ |
| 🎨 **Wallpaper** | 9 variante MerphisOS | ✅ |
| 🔔 **Boot Splash** | Plymouth (spinfinity) | ✅ |
| 👤 **User live** | `live` / `merphisos`, auto-login SDDM | ✅ |

---

## 🔒 Caracteristici principale

### Privacy by Design

MerphisOS este construit cu **zero încredere în telemetrie**. Implicit:

- **KDE Plasma**: Feedback dezactivat, recent files OFF, activity tracking OFF
- **Baloo** (indexer fișiere): Complet dezactivat
- **LibreWolf**: Toată telemetria Mozilla blocată via `lockPref` system-wide
- **VLC**: Update check și metadata network dezactivate
- **Flatpak**: Auto-update check dezactivat
- **DrKonqi** (crash reports): Dezactivat
- **systemd**: Journal volatile (50M maxim), coredump complet dezactivat
- **Connectivity check**: Dezactivat în NetworkManager

### Securitate Implicită

- 🔥 **Firewall nftables**: Politica DROP pe input/forward, allow established + SSH LAN
- 🔐 **Quad9 DoT**: Tot DNS-ul e criptat și validat DNSSEC
- 📡 **MAC randomizare**: Activă la scanare WiFi
- ⚙️ **sysctl hardening**: ASLR, kptr_restrict, dmesg_restrict, ptrace_scope, panic_on_oops
- 🛡️ **AppArmor**: Profiluri active implicite

### Hybrido DE

Comută între experiența macOS și Windows cu o singură comandă:

```bash
# Mod macOS (implicit)
sudo switch-mode macos

# Mod Windows
sudo switch-mode windows
```

- **macOS mode**: Panel sus + Global Menu + butoane stânga + culori macOS
- **Windows mode**: Taskbar jos + butoane dreapta + culori Windows 11

---

## 🖥️ Cerințe sistem

| Componentă | Minim | Recomandat |
|---|---|---|
| **CPU** | x86_64, 2 core | 4+ core |
| **RAM** | 2 GB | 8+ GB |
| **Depozitare** | 20 GB | 64+ GB SSD |
| **GPU** | Orice suportat de Linux | AMD/NVIDIA (nou) |
| **Boot** | UEFI (x64) | UEFI + Secure Boot (în lucru) |
| **Monitor** | 1024x768 | 1920x1080+ |

---

## 🔧 Build din sursă

```bash
# Prerequisites: Docker, ~25GB disk space
git clone https://github.com/serverul/merphisOS
cd merphisOS

# 1. Build rootfs (Plasma 6 + apps + kernel + live-boot)
docker build -t merphisos-rootfs -f Dockerfile.merphisos-rootfs .

# 2. Export rootfs
mkdir -p /tmp/merphis-build
docker create --name rootfs-temp merphisos-rootfs:latest
docker export rootfs-temp -o /tmp/merphis-build/rootfs.tar
docker rm rootfs-temp

# 3. Build ISO generator
docker build -t merphisos-iso -f Dockerfile.merphisos-iso .

# 4. Generate ISO
docker run --rm \
  -v /tmp/merphis-build/rootfs.tar:/build/rootfs.tar:ro \
  -v $(pwd)/artwork:/build/artwork:ro \
  -v $(pwd)/calamares:/build/calamares:ro \
  -v $(pwd)/config:/build/config:ro \
  -v /tmp/merphis-build/output:/build/output \
  merphisos-iso:latest \
  /bin/bash /build/build-iso.sh

# ISO is at /tmp/merphis-build/output/merphisos-0.3.1-beta-hybrido-amd64.iso
```

---

## 🏗️ Arhitectura sistemului

```
MerphisOS Stack
┌──────────────────────────────────────────────────────┐
│               HYBRIDO DESKTOP                         │
│  Plasma 6 + KWin Wayland + themes + Nemo + apps     │
├──────────────────────────────────────────────────────┤
│               MERPHISOS CONFIG                        │
│  Telemetrie OFF + nftables + DoT + sysctl hardening │
├──────────────────────────────────────────────────────┤
│               DEBIAN 13 TRIXIE                        │
│  linux-image-amd64 + live-boot + systemd + udev     │
├──────────────────────────────────────────────────────┤
│               HARDWARE (x86_64 UEFI)                  │
└──────────────────────────────────────────────────────┘
```

Vezi [docs/architecture.md](docs/architecture.md) pentru detalii complete.

---

## 🎯 Roadmap

| Fază | Status |
|---|---|
| Phase 1: Alpha ISO (Plasma 6 minimal, live-boot) | ✅ |
| Phase 2: Hybrido DE + LibreWolf + artwork + switch-mode | ✅ |
| Phase 3a: Plymouth boot splash | ✅ |
| Phase 3b: System hardening (sysctl, nftables, DoT, MAC) | ✅ |
| Phase 3c: Kernel custom (Kernel.org + hardening) | 🔄 În lucru |
| Phase 4: Calamares installer + live user | ✅ |
| Phase 5: Telemetrie complet oprită + privacy defaults | ✅ |
| Phase 6: Secure Boot + ISO signing | 📅 Planificat |
| **v1.0 Release** | 📅 După Phase 3c + 6 |

Vezi [ROADMAP.md](ROADMAP.md) pentru detalii.

---

## 📚 Documentație

- 📖 [Manual de utilizare](docs/user-manual.md) — Ghid complet pentru utilizatori
- 🏗️ [Arhitectura sistemului](docs/architecture.md)
- 🎨 [Hybrido Design](docs/hybrido-design.md) — Specificații design
- 🔒 [Privacy Policy](docs/privacy-policy.md) — Politica de confidențialitate
- 📋 [Changelog](https://github.com/serverul/merphisOS/releases)

---

## 📜 Licență

**GNU General Public License v3.0** — MerphisOS este software liber.

Poți folosi, modifica și distribui liber, cu condiția să păstrezi aceeași licență.

---

## 🤝 Contribuții

Nu e încă deschis pentru contribuții externe, dar dacă ai idei sau bug reports,
deschide un issue pe GitHub.

---

<div align="center">
  <sub>MerphisOS — construit cu ❤️ și mult ☕</sub>
</div>

# MerphisOS

> **Your system, your rules.**

[![]()]() *— logo aici —*

**MerphisOS** este un sistem de operare Linux **privacy-first, securizat și
frumos**, construit pentru oameni care își găzduiesc singuri serviciile și
prețuiesc confidențialitatea fără compromisuri.

Bazat pe **Debian 13 "Trixie"**, cu **kernel custom**, **Hybrido Desktop
Environment** (un mediu desktop care combină ce e mai bun din macOS și
Windows), și o suită de aplicații alese cu grijă pentru confidențialitate
și productivitate.

---

## ✨ Caracteristici

| | |
|---|---|
| 🔒 **Privacy by design** | Zero telemetry, DNS-over-HTTPS implicit, firewall activ, MAC randomizare, fără servicii care sună acasă |
| 🎨 **Hybrido DE** | Mediu desktop care arată și funcționează ca **macOS** sau **Windows** — alegi tu printr-un toggle |
| ⚡ **Kernel custom** | Ultima versiune Linux stabilă, compilat cu hardening maxim, doar driverele necesare |
| 📦 **Flatpak + Distrobox** | Aplicații GUI sandboxed + tool-uri CLI în containere — sistemul de bază rămâne curat |
| 🏠 **Self-hosting ready** | Vaultwarden, Mullvad VPN, servicii Docker — configurate din prima |
| 🚀 **Plug and play** | Instalezi și ai: LibreWolf, VLC, Stremio, Bitwarden, terminal, Git, Python, Node.js — totul gata |

---

## 🖼️ Hybrido Desktop Environment

**Hybrido** este inima MerphisOS. Un mediu desktop care nu te obligă să alegi
între estetică și funcționalitate.

### Modul macOS

- Panel floating sus cu Global Menu
- Launchpad-style app launcher
- Window controls în stânga
- Dock opțional
- Workspace-uri cu tranziții fluide

### Modul Windows

- Taskbar jos cu buton Start
- Start Menu clasic
- System tray + Action Center
- Snap Assist cu ghidaje vizuale
- Window controls în dreapta

> 🔄 **Comutare instant** — o setare în System Settings schimbă tot layout-ul,
> tema, și comportamentul.

---

## 📦 Aplicații Implicite

| Categorie | Aplicație |
|---|---|
| 🌐 Browser | **LibreWolf** + **Mullvad Browser** |
| 📺 Media | **VLC**, **Stremio** |
| 🔒 VPN | **Mullvad VPN** |
| 🆔 Passwords | **Bitwarden** (Vaultwarden-ready) |
| 🖥️ Terminal | **Kitty** |
| 🗂️ File Manager | **Nemo** |
| 📝 Editor | **Kate** (Vim mode) |
| 🐳 Containers | **Podman** + **Distrobox** |
| 🧰 Dev Tools | Git, Python 3, Node.js LTS, GCC |

---

## 🔧 System Requirements

| Component | Minimum | Recommended |
|---|---|---|
| **CPU** | Dual-core x86_64 | Quad-core+ |
| **RAM** | 4 GB | 8 GB+ |
| **Storage** | 20 GB | 64 GB+ (SSD) |
| **GPU** | Intel/AMD/NVIDIA | Any modern GPU |

---

## 🚧 Status

**MerphisOS este în faza de proiectare și dezvoltare incipientă.**

- [x] Specificație tehnică draft
- [ ] Kernel config și build system
- [ ] Hybrido DE teme și layout-uri
- [ ] Scripturi de build
- [ ] ISO bootabil
- [ ] Testare pe hardware real
- [ ] Prima lansare

---

## 🏗️ Build

*(în curând — scripturile de build sunt în lucru)*

```bash
git clone git@github.com:serverul/merphisOS.git
cd merphisOS
./tools/build.sh
```

---

## 🤝 Contribuții

MerphisOS este un proiect personal. Dacă ai găsit ceva util, deschide un issue
sau dă un semn. ✌️

---

## 📜 Licență

*(de stabilit — GPLv3 sau MIT)*

---

*Creat cu 🧠 de Vlad și Merphis.*

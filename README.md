# MerphisOS 0.2-beta — Hybrido DE 🚀

> **Your system, your rules.**

**MerphisOS** este un sistem de operare Linux **privacy-first, securizat și frumos**, construit pe **Debian 13 "Trixie"**, cu **Hybrido Desktop Environment** și **Plasma 6** pe **Wayland** (zero X11).

---

## 🎯 Latest Release: v0.2-beta

### ✨ Ce e nou
| Componentă | Status |
|---|---|
| 🖥️ **Plasma 6.3.5** + KWin Wayland | ✅ |
| 🌐 **LibreWolf 151** (browser privat) | ✅ |
| 🗂️ **Nemo** file manager (înlocuiește Dolphin) | ✅ |
| 🖥️ **Kitty** terminal | ✅ |
| 📺 **VLC 3.0.23** | ✅ |
| 🎨 **Hybrido macOS + Windows themes** | ✅ |
| 🖼️ **Wallpaper MerphisOS oficial** | ✅ (9 variante inclusiv space nebula) |
| 🔒 **nftables, Quad9 DoT, MAC randomizare** | ✅ |
| 🔔 **SDDM** login manager cu logo MerphisOS | ✅ |
| 🚫 **X11** — exclus complet (EOL) | ✅ |

### 📥 Download ISO
> **⚠️ Available at:** Contactează-mă pentru link-ul de download al ISO-ului (1.9GB)

### 🔧 Build from source
```bash
# Prerequisites: Docker, ~20GB disk space
git clone https://github.com/serverul/merphisOS
cd merphisOS

# Build rootfs Docker image
docker build -t merphisos-rootfs -f Dockerfile.rootfs .

# Build ISO
mkdir -p /tmp/merphisos-build && cd /tmp/merphisos-build
docker export $(docker create merphisos-rootfs:latest) -o rootfs.tar
# ... (see tools/build-iso.sh for full pipeline)
```

---

## 🔒 Caracteristici principale

- **Privacy by design**: Zero telemetry, DNS-over-TLS (Quad9), firewall nftables, MAC randomizare
- **Hybrido DE**: Comută între macOS și Windows styling
- **Flatpak + Flathub** pre-configurat
- **Kernel custom** (în lucru)
- Utilizator `vladd` (parola: `merphisos`)

---

## 🏗️ Roadmap

- [x] **Phase 1**: Alpha ISO (Plasma 6 minimal, fără X11)
- [x] **Phase 2**: Hybrido DE + LibreWolf + artwork
- [ ] **Phase 3**: Kernel custom + boot splash Plymouth
- [ ] **Phase 4**: switch-mode.sh (macOS/Windows toggle)
- [ ] **Phase 5**: Calamares installer

---

## 📜 License

GNU General Public License v3.0

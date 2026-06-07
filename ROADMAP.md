# MerphisOS — ROADMAP

> De la idee la ISO bootabil.

---

## 🎯 Faza 0: Proiectare  *(acum — mai 2026)*

- [x] Stabilire specificații tehnice
- [x] Alegere bază (Debian 13 Trixie)
- [x] Kernel approach (latest stable + custom hardening)
- [x] Hybrido DE concept (Plasma 6 + custom themes)
- [ ] Finalizare SPEC.md ✅ *(asta)*
- [ ] Configurare repo și structură
- [ ] Instalare și testare mkosi

**Output:** Repo populat cu documentație.  

---

## 🧱 Faza 1: Bootstrap (săptămâna 1-3) ✅

- [x] Instalare și învățare mkosi
- [x] Primul ISO bootabil Debian Trixie
- [x] Docker-based build pipeline
- [x] Kernel + initrd în ISO
- [x] Configurări de bază (DNS, firewall, sysctl, utilizator)
- [x] Pachete de bază (NetworkManager, PipeWire, Flatpak, apps)
- [x] Scripturi de build funcționale
- [ ] Kernel custom (în lucru)
- [ ] Hybrido DE în ISO

**Output:** ISO bootabil cu Debian Trixie + Plasma 6.  
**Test:** Boot în QEMU → login → terminal → shutdown.

---

## 🎨 Faza 2: Hybrido DE (săptămâna 4-8)

- [ ] Temă Plasma: Hybrido-macOS (culori, decorațiuni, transparență)
- [ ] Temă Plasma: Hybrido-Windows
- [ ] Panel layout: macOS (top bar floating)
- [ ] Panel layout: Windows (bottom taskbar)
- [ ] Script: `switch-mode.sh` — comută între macOS și Windows
- [ ] Nemo default file manager (configurare + integrare)
- [ ] Înlocuire/eliminare aplicații KDE nedorite
- [ ] Custom boot splash (Plymouth theme)
- [ ] Custom SDDM login screen

**Output:** ISO bootabil cu Hybrido DE funcțional.  
**Test:** Boot → toggle mode → apps → totul merge.

---

## 📦 Faza 3: Aplicații și Configurări (săptămâna 9-12)

- [ ] LibreWolf pre-instalat + configurat privacy max
- [ ] Mullvad Browser (Flatpak)
- [ ] VLC + codec-uri
- [ ] Stremio (Flatpak)
- [ ] Mullvad VPN + configurare inițială
- [ ] Bitwarden (extensie Firefox + Flatpak)
- [ ] Kitty terminal
- [ ] Podman + Distrobox
- [ ] Dev tools: Git, Python, Node.js, GCC
- [ ] Flatpak + Flathub configurat
- [ ] Firewall: nftables reguli default
- [ ] DNS-over-HTTPS configurat
- [ ] AppArmor profile-uri
- [ ] NetworkManager fără connectivity check

**Output:** ISO cu toate aplicațiile și configurațiile de privacy.  
**Test:** Instalare → totul funcționează fără configurări suplimentare.

---

## 🔐 Faza 4: Securitate și Semnare (săptămâna 13-14)

- [ ] Kernel signing (GPG + pesign)
- [ ] Module signing
- [ ] Secure Boot support
- [ ] Repo .deb propriu + Release.gpg
- [ ] ISO checksum + semnătură detached
- [ ] Testare: atacuri comune (USB, network, privilege escalation)

**Output:** MerphisOS verificabil criptografic.  
**Test:** `verify-iso.sh` → totul OK.

---

## 🧪 Faza 5: Testare (săptămâna 15-16)

- [ ] QEMU: boot, shutdown, suspend, resume
- [ ] QEMU: toate aplicațiile funcționează
- [ ] QEMU: firewall, DNS, VPN
- [ ] Hardware real: laptopul tău
- [ ] Hardware real: WiFi, Bluetooth, audio, webcam
- [ ] Hardware real: suspenda/trezire, multi-monitor
- [ ] Instalare pe disc real (testare installer)
- [ ] Bug fixing

**Output:** MerphisOS stabil pe hardware real.

---

## 🚀 Faza 6: Lansare (săptămâna 17+)

- [ ] Website / landing page minimal
- [ ] Release notes v1.0
- [ ] ISO publicat
- [ ] Anunț

**Output:** MerphisOS v1.0 🎉

---

## Timeline Estimat

```
Mai 2026       Iunie         Iulie        August        Septembrie
│              │             │            │             │
▓▓▓▓▓░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
Faza 0   Faza 1      Faza 2         Faza 3    F4 F5    F6
(acum)   (bootstrap) (Hybrido DE)   (apps)    (sec)    (lansare)
```

**Total estimat:** ~4-5 luni până la v1.0.

---

*Note: Timeline-ul e orientativ. Preferăm corectitudine în loc de viteză.*

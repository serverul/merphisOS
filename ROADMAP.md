# MerphisOS — ROADMAP v1.0

> De la idee la ISO bootabil cu installer.

---

## ✅ Finalizate

- [x] **Phase 0**: Proiectare, SPEC, ADR-uri
- [x] **Phase 1**: Bootstrap — ISO Debian 13 Trixie + Plasma 6 + live-boot
- [x] **Phase 2**: Hybrido DE — teme macOS/Windows, artwork, switch-mode.sh
- [x] **Phase 2b**: Fix live-boot (kernel panic VirtualBox — lipsea `live-boot`)
- [x] **Phase 3a**: Plymouth boot splash (spinfinity default)
- [x] **Phase 3b**: System hardening (sysctl, nftables, Quad9 DoT, MAC random)
- [x] **Phase 4a**: switch-mode.sh funcțional (macOS / Windows toggle)
- [x] **Phase 4b**: Calamares installer + branding MerphisOS
- [x] **Phase 4c**: Live user generic (`live`/`merphisos`, auto-login SDDM)
- [x] **Phase 4d**: Telemetrie complet oprită system-wide (KDE, LibreWolf, VLC, Flatpak, systemd)
- [x] **Phase 4e**: Hybrido first-run script (setup inițial desktop)
- [x] **Phase 4f**: Telemetrie KDE completă (kuserfeedback, Baloo, recent files, DrKonqi)

### Release-uri

- [x] **v0.1-alpha** (2026-06-07) — primul ISO bootabil
- [x] **v0.2-beta** (2026-06-07) — Hybrido DE + artwork + LibreWolf
- [x] **v0.3-beta** (2026-06-07) — live user + Calamares + telemetrie + securitate
- [x] **v0.3.1-beta** (2026-06-07) — fix GRUB (versiune, sintaxă, kernel copy) + documentație

---

## 🔄 În lucru

- [ ] **Phase 3c**: Kernel custom (Kernel.org latest stable + hardening patches)

---

## 🗓️ Planificate (v1.0)

- [ ] **Phase 5a**: Secure Boot + ISO signing
- [ ] **Phase 5b**: Custom Plymouth theme MerphisOS
- [ ] **Phase 5c**: Hybrido App Launcher (Rust, wlroots)
- [ ] **Phase 5d**: Testare hardware variat (laptop, desktop, VM)
- [ ] **Phase 6**: Beta public + feedback din comunitate
- [ ] **v1.0**: Release stabil

---

## 📋 Timeline estimativ

```
Săptămâna 1-2: Stabilizare ISO (bug fixes din testare)
Săptămâna 3:   Kernel custom (config, build, integrare ISO)
Săptămâna 4:   Testare hardware real + Secure Boot
Săptămâna 5:   Bug fixes + stabilizare
Săptămâna 6:   v1.0 Release
```

---

## 🎯 Priorități pentru următoarea iterație

1. 🔧 **Kernel custom** — compilat cu hardening patches, modul signing
2. 🖼️ **Plymouth theme** — animație personalizată MerphisOS
3. 🔐 **Secure Boot** — semnare kernel + GRUB
4. 🧪 **Testare** — laptopuri reale (ThinkPad, Dell, ASUS)
5. 📦 **Beta public** — ISO public + canale de feedback

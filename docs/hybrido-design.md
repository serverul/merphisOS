# Hybrido DE v0.3.1-beta — Design Specification

> Mediu desktop hibrid: macOS și Windows, la alegere.

---

## 1. Filosofie

Hybrido nu este un "remix" sau o temă superficială. Este o **experiență
completă** care respectă convențiile ambelor sisteme de operare majore,
permițând utilizatorului să-și aleagă paradigma preferată.

**Principii:**
- **Fidelitate** — modul macOS arată și se comportă ca macOS, nu „ca un Linux
  cu un dock pus"
- **Consistență** — fiecare mod este complet și consistent, nu jumătate din
  elemente
- **Viteză** — nimic nu e mai lent decât Plasma stock. Optimizăm configurarea,
  nu adăugăm bloat.
- **Respect pentru utilizator** — setările sunt simple, documentate,
  previzibile

---

## 2. Arhitectura Componentelor

```
Hybrido DE
├── Compositor: KWin (Plasma 6, Wayland)
│   ├── Regular windows (floating mode)
│   ├── Tiling mode (opțional, KWin script)
│   └── Animations (macOS-style genie / Windows-style fade)
│
├── Shell: Plasma Shell (plasma-workspace)
│   ├── Panel layout loadabil din fișier JS
│   └── Widget-uri stock + custom (separator, spaci, global menu)
│
├── Window Decorations (decoration plugin)
│   ├── Hybrido-macOS — butoane stânga, colțuri mari rotunjite
│   └── Hybrido-Windows — butoane dreapta, colțuri mici
│
├── Theme (Global Plasma Theme)
│   ├── hybrido-macos — dark/light, accent dinamic
│   └── hybrido-windows — dark/light, accent dinamic
│
├── App Launcher
│   ├── Kickoff customizat (macOS grid mode / Windows list mode)
│   └── (Viitor) propriul launcher în Rust
│
├── File Manager: Nemo (înlocuiește Dolphin)
│   ├── Integrare KDE (merge pe Qt, dar Nemo e GTK)
│   └── Tema Kvantum + GTK3 (consistență vizuală)
│
└── Switch Script
    ├── switch-mode.sh — comută teme, paneluri, decorațiuni
    └── Integrare în System Settings → Hybrido → Mode
```

---

## 3. Modul macOS

### Panel (sus, floating)

```
┌──────────────────────────────────────────────────────┐
│    │  App Name  │          │  🔔  │  🔋  │  🕐  │  │
│      │  ⏤⏤⏤⏤   │          │      │      │      │  │
│      │  File  Edit  View    │      │  85%  │ 14:30│  │
└──────────────────────────────────────────────────────┘
```

- **Poziție**: sus
- **Stil**: floating (margin stânga/dreapta, colțuri rotunjite)
- **Transparență**: 80% blur (transparent când fereastra nu e maximizată)
- **Conținut**:
  - Stânga: Apple logo () → meniu MerphisOS (About, Settings, Sleep, Shutdown)
  - Centru: numele aplicației active
  - Dreapta: notificări, ceas, baterie, WiFi, control center
- **Global Menu**: meniul aplicației active apare în panel (AppName File Edit View...)
- **Comportament**: panelul devine opac când o fereastră e maximizată

### Dock (jos, opțional)

- Default ascuns, activabil din Settings
- Poziție: jos, centrat
- Stil: floating, cu colțuri rotunjite, transparență
- Conținut: aplicații favorite, aplicații recente, trash
- Animații: icon bounce la deschidere aplicație (ca macOS)
- Nu folosim Latte Dock (e deprecated). Folosim **Plank** sau **implementare
  proprie** pe wlroots (dacă Latte e mort).

### App Launcher

- **Layout**: Launchpad-style (grid de iconițe mari, 7x5 sau adaptiv)
- **Deschidere**: gest trackpad (pinch cu 4 degete) sau click pe  → Launchpad
- **Căutare**: Spotlight-style (cmd + spațiu → bară de căutare centrată)
- Alternativ: **Kickoff customizat** (Plasma 6 permite layout-uri)

### Window Controls

- **Stânga sus**: ⬤ (închide) ⬤ (minimizează) ⬤ (maximizează)
- **Animație minimize**: genie effect (sau măcar zoom)

### Workspaces / Spaces

- **Comutare**: 3 degete stânga/dreapta pe trackpad
- **Vizualizare**: Mission Control-style (Exposé) cu toate ferestrele
- **+Desktop**: workspace-uri separate (ca macOS Spaces)

### Keyboard Shortcuts macOS-style

| Acțiune | Shortcut |
|---|---|
| Copy | ⌘ C |
| Paste | ⌘ V |
| Cut | ⌘ X |
| Undo | ⌘ Z |
| Save | ⌘ S |
| Find | ⌘ F |
| Switch app | ⌘ Tab |
| Spotlight | ⌘ Spațiu |
| Close window | ⌘ W |

---

## 4. Modul Windows

### Taskbar (jos, fix)

```
┌────────────────────────────────────────────────────────────┐
│  ■ Start  │    │  🌐  │  🎵  │         │  🔔  │  🕐  │  │
│            │  Nemo │  LibreWolf   │         │      │14:30 │  │
│            │       │              │         │      │      │  │
└────────────────────────────────────────────────────────────┘
```

- **Poziție**: jos
- **Stil**: fix (ocupă toată lățimea)
- **Conținut**:
  - Stânga: buton Start, aplicații pinuite, aplicații deschise
  - Dreapta: system tray (ceas, WiFi, baterie, volum, notificări)
- **Taskbar buttons**: text + icon, grupare după aplicație (opțional)
- **Click dreapta**: meniu contextual (Task Manager, Taskbar settings)
- **Comportament**: auto-hide opțional

### Start Menu

```
┌──────────────────────────┐
│  🔍  Search apps         │
├──────────────────────────┤
│  📌 Pinned               │
│  ├── LibreWolf           │
│  ├── Nemo                │
│  ├── VLC                 │
│  └── Settings            │
├──────────────────────────┤
│  🧾 Recently added       │
│  └── ...                 │
├──────────────────────────┤
│  ⚡ Recommended           │
├──────────────────────────┤
│  👤 Vlad    ⚙️  🔌  ⏻   │
└──────────────────────────┘
```

- Layout: Windows 11-style (search sus, pinned apps, recommended)
- User picture + nume în stânga jos
- Quick actions: Settings, Power, Lock
- Căutare: integrată cu KRunner (Plasma)

### Action Center

- Deschidere: click pe iconița de notificări (dreapta taskbar)
- Conținut: notificări + quick settings (WiFi, Bluetooth, VPN, Night Mode, etc.)
- Similar cu Windows 11 Action Center

### Window Controls

- **Dreapta sus**: ⬤ (minimizează) ⬤ (maximizează) ⬤ (închide)

### Keyboard Shortcuts Windows-style

| Acțiune | Shortcut |
|---|---|
| Copy | Ctrl C |
| Paste | Ctrl V |
| Cut | Ctrl X |
| Start Menu | Win |
| File Explorer | Win + E |
| Settings | Win + I |
| Search | Win + S |
| Lock | Win + L |
| Close window | Alt + F4 |
| Switch app | Alt + Tab |

---

## 5. Tema Vizuală Unificată

### Elemente comune (ambele moduri)

| Element | Specificație |
|---|---|
| **Colțuri ferestre** | Rotunjite (8px modul Windows, 12px modul macOS) |
| **Blur / Transparență** | Da, pe panel-uri și ferestre active |
| **Dark mode** | Implicit, toggle light/dark în Settings |
| **Accent color** | Dinamică (extrage dominantă din wallpaper) — ca Windows 11 + macOS |
| **Iconițe** | Set propriu Hybrido (sau Tela Circle modificat) |
| **Font** | Inter (open-source) — similar cu San Francisco |
| **Sunete** | Custom sound theme (subtile, macOS sau Windows-style) |

### Tranziția între Moduri

Utilizatorul merge în **System Settings → Hybrido → Mode** și alege:

```
[ macOS  ● ]  [ Windows ○ ]
```

Asta execută `switch-mode.sh` care:

1. Schimbă tema globală (hybrido-macos → hybrido-windows)
2. Reîncarcă panel layout-ul (macOS → Windows)
3. Schimbă decoration plugin-ul (butoane stânga → dreapta)
4. Actualizează shortcut-urile keyboard (⌘ → Ctrl)
5. Reconfigurează KRunner (Spotlight-style vs Win+S)
6. Notifică utilizatorul: "Mod schimbat cu succes ✅"

Tranziția durează < 1 secundă și nu necesită logout.

---

## 6. Aplicații Implicite și Integrare

| Aplicație | Rol | Integrare |
|---|---|---|
| **Nemo** | File manager | Default for folders, desktop icons |
| **Kitty** | Terminal | Default terminal emulator |
| **LibreWolf** | Browser | Default browser, pinned to panel/dock |
| **VLC** | Media player | Default for all media files |
| **Spectacle** | Screenshots | Print Screen key binding |
| **Kate** | Text editor | Default for text/code files |

---

## 7. First Run Experience

La prima pornire după instalare:

1. **Welcome Screen** — "Bun venit în MerphisOS! Alege cum vrei să arate
   sistemul tău:"
   - [🖥️ macOS style] [🪟 Windows style]
2. Configurare rapidă:
   - Nume utilizator + parolă
   - Hostname
   - Timezone
   - WiFi (dacă e cazul)
3. Hybrido se activează cu modul ales
4. Tutorial scurt (2-3 ecrane) despre features unice

---

## 8. Performanță

**Target:** Hybrido DE trebuie să se simtă la fel de rapid ca Plasma 6 stock.

| Măsurătoare | Target |
|---|---|
| RAM idle (fără apps) | < 800MB |
| Boot time | < 10s (NVMe) |
| App launch time | < 1s (native) |
| Mode switch time | < 1s |
| Animations | 60fps constant |

---

## 9. Implementare Tehnică

### Pachete Necesare

```
Base:            plasma-desktop, plasma-workspace, kwin, kate, spectacle
macOS mode:      plasma-workspace (global menu widget), plank (dock)
Windows mode:    (inclus în plasma-workspace, layout custom)
File manager:    nemo, nemo-previews, nemo-image-converter
Terminal:        kitty
Theme engine:    qt6-style-kvantum, kvantum, gtk3-nocsd
```

### Fișiere de Configurare

```
~/.config/
├── hybrido/
│   ├── mode.conf              # current mode (macos/windows)
│   └── settings.conf          # hybrido-specific settings
├── plasma-org.kde.plasma.desktop-appletsrc  # panel layouts
├── kwinrc                    # window decorations, compositor
├── breezerc                  # theme settings
├── konsolerc                 # (dezactivat, folosim kitty)
├── kcminputrc                # keyboard shortcuts
├── mimeapps.list             # default apps
└── qt6ct.conf                # Qt6 theming
```

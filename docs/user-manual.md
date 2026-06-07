# Manual de Utilizare — MerphisOS v0.3.1-beta

> Ghid complet pentru utilizarea sistemului de operare MerphisOS
> cu Hybrido Desktop Environment.

---

## Cuprins

1. [Prima pornire](#1-prima-pornire)
2. [Interfața Hybrido DE](#2-interfața-hybrido-de)
3. [Comutarea între modurile macOS și Windows](#3-comutarea-între-modurile-macos-și-windows)
4. [Aplicații preinstalate](#4-aplicații-preinstalate)
5. [Securitate și confidențialitate](#5-securitate-și-confidențialitate)
6. [Rețea și conectivitate](#6-rețea-și-conectivitate)
7. [Instalarea MerphisOS pe hard disk](#7-instalarea-merphisos-pe-hard-disk)
8. [Telemetria — ce e oprit și de ce](#8-telemetria--ce-e-oprit-și-de-ce)
9. [Depanare](#9-depanare)
10. [Resurse și referințe](#10-resurse-și-referințe)

---

## 1. Prima pornire

### Pornește de pe ISO

1. Montează ISO-ul în VirtualBox (sau scrie-l pe un stick USB cu `dd` sau Rufus)
2. Pornește sistemul
3. Vei vedea meniul GRUB cu următoarele opțiuni:
   - **MerphisOS 0.3-beta — Hybrido DE** — boot normal
   - **MerphisOS 0.3-beta (VirtualBox)** — dacă rulezi în VirtualBox cu probleme grafice
   - **MerphisOS 0.3-beta (Safe Mode)** — mod de recuperare (fără acpi, noapic)
   - **MerphisOS 0.3-beta (Verify & Test)** — mod debug cu loguri detaliate
   - **🔁 Reboot** — repornește
   - **⏻ Shutdown** — oprește

Selectează prima opțiune (sau VirtualBox dacă rulezi în VM).

### Autentificare

Sesiunea live se autentifică **automat** în SDDM cu utilizatorul `live`.
Nu trebuie să introduci parola.

Dacă totuși ți se cere:
- **Username:** `live`
- **Parola:** `merphisos`

> ⚠️ Sesiunea live este **volatilă**. Orice modificare se pierde la reboot.
> Folosește **Calamares Installer** (icon pe desktop) pentru instalare permanentă.

---

## 2. Interfața Hybrido DE

Hybrido DE este un mediu desktop hibrid care poate funcționa în două moduri:
**macOS** (implicit) și **Windows**.

### Mod implicit: macOS

```
┌─────────────────────────────────────────────────────────┐
│    │  App Name              │  🔔  │  🔋  │  🕐     │
│      │  File  Edit  View      │      │  85%  │  14:30  │
└─────────────────────────────────────────────────────────┘

                     Desktop curat

              [   Aplicații favorite   ]
```

- **Panel sus** cu Global Menu, ceas, baterie, notificări
- **Butoane ferestre în stânga** (🔴 🟡 🟢)
- **Colțuri rotunjite** la ferestre
- **Global Menu** — meniul aplicației active apare în panel

### Scurtături tastatură importante

| Combinație | Acțiune |
|---|---|
| **Meta (Super/Windows)** | Lansator aplicații (Kickoff) |
| **Alt + Tab** | Comutare între aplicații |
| **Meta + Space** | Căutare aplicații/setări (KRunner) |
| **Meta + L** | Blocare ecran |
| **Print Screen** | Screenshot |
| **Ctrl + Alt + T** | Terminal (Kitty) |
| **Ctrl + Alt + Delete** | Task Manager |
| **Meta + D** | Arată/ascunde desktopul |
| **Meta + ←/→/↑/↓** | Snap ferestre (încadrare stânga/dreapta/sus/jos) |

---

## 3. Comutarea între modurile macOS și Windows

### Din terminal

```bash
# Mod macOS (implicit)
sudo switch-mode macos

# Mod Windows
sudo switch-mode windows
```

### Ce se schimbă

| Element | Mod macOS | Mod Windows |
|---|---|---|
| **Panel** | Sus, floating | Jos, taskbar |
| **Butoane ferestre** | Stânga (🔴 🟡 🟢) | Dreapta (— 🗖 ✕) |
| **Colțuri ferestre** | Mari, rotunjite | Mici, drepte |
| **Culori** | Albastru accent (0,122,255) | Albastru Win11 (0,120,215) |
| **Fundal** | Gradient închis | Solid închis |
| **Global Menu** | Da, în panel | Nu (meniul în fereastră) |
| **Lansator** | Grid (Launchpad-style) | Listă (Start Menu-style) |

> 💡 Tema activă se aplică instant — nu e nevoie de restart sau re-login.

### La prima pornire

La prima autentificare, scriptul `hybrido-first-run` rulează automat și:
1. Dezactivează Baloo (indexare fișiere)
2. Activează modul implicit macOS
3. Configurează panel-ul și wallpaper-ul
4. Suprimă popup-urile KDE Welcome

---

## 4. Aplicații preinstalate

### Sistem

| Aplicație | Rol | Comandă |
|---|---|---|
| **Kitty** | Terminal | `kitty` sau Ctrl+Alt+T |
| **Nemo** | File Manager | Icon în panelul de jos |
| **Kate** | Editor de text | `kate` |
| **Ark** | Arhivator | `ark` |
| **System Settings** | Setări sistem | Icon în panel |
| **Discover** | Manager aplicații (Flatpak) | `discover` |

### Internet

| Aplicație | Rol | Notă |
|---|---|---|
| **LibreWolf** | Browser web | Privacy-first, telemetrie Mozilla blocată |
| **VLC** | Media player | Update check dezactivat |

### Instalare aplicații noi

```bash
# Aplicații Flatpak (recomandat, sandboxed)
flatpak install flathub org.onlyoffice.desktopeditors
flatpak install flathub com.discordapp.Discord

# Aplicații native (.deb)
sudo apt update && sudo apt install gimp inkscape

# CLI tools
sudo apt install htop neofetch curl git
```

---

## 5. Securitate și confidențialitate

### Configurații implicite

MerphisOS pornește cu următoarele măsuri active:

#### Firewall (nftables)

```bash
# Verifică status firewall
sudo nft list ruleset

# Regulile implicite:
# - DROP tot traficul incoming (except established/related)
# - ALLOW loopback (localhost)
# - ALLOW SSH din rețelele locale (192.168.x.x, 10.x.x.x, 172.16-31.x.x)
# - ALLOW DHCP (port 67-68)
# - ACCEPT tot traficul outgoing
# - RATE LIMIT ICMP la 10 pachete/secundă
```

#### DNS — Quad9 Over-TLS

```bash
# Verifică DNS-ul activ
resolvectl status

# Ar trebui să vezi:
#   Current DNS Server: 9.9.9.9
#   DNS Servers: 9.9.9.9 149.112.112.112
#   DNSOverTLS: yes
#   DNSSEC: yes
```

#### MAC randomizare

```bash
# Verifică MAC-ul curent al interfeței WiFi
ip link show wlan0
# MAC-ul se randomizează la fiecare conectare la o rețea nouă
```

#### Kernel Hardening

```bash
# Verifică setările sysctl active
sudo sysctl kernel.randomize_va_space   # ar trebui să fie 2
sudo sysctl kernel.kptr_restrict        # ar trebui să fie 2
sudo sysctl kernel.dmesg_restrict       # ar trebui să fie 1
sudo sysctl kernel.yama.ptrace_scope    # ar trebui să fie 1
```

---

## 6. Rețea și conectivitate

### Conectare WiFi

```bash
# Din terminal
nmcli dev wifi list
nmcli dev wifi connect "SSID" password "parola"

# Sau din GUI: click pe icon WiFi din panel → Selectează rețea
```

### Conexiune la distanță (SSH)

Firewall-ul permite SSH doar din rețelele locale (192.168.x.x, 10.x.x.x, 172.16-31.x.x).
SSH din internet e blocat implicit.

```bash
# Pornește SSH server
sudo systemctl enable --now ssh

# Conectare de la alt calculator
ssh live@<IP_MERPHISOS>
```

### VPN

```bash
# Instalează WireGuard
sudo apt install wireguard

# Configurare client (necesită fișier de configurare de la furnizor)
sudo cp client.conf /etc/wireguard/wg0.conf
sudo wg-quick up wg0
```

---

## 7. Instalarea MerphisOS pe hard disk

> ⚠️ Backup-uiește datele înainte de instalare!

1. Pe desktop, dă dublu-click pe **"Install MerphisOS"** (icon Calamares)
2. Urmează pașii:
   - **Welcome**: Alege limba (română sau engleză)
   - **License**: Acceptă GPLv3
   - **Partiționare**: Alege "Erase disk" (șterge tot) sau **"Manual partitioning"** (avanat)
   - **Utilizator**: Creează un cont nou (NU vei mai folosi `live`)
   - **Bootloader**: Alege hard disk-ul principal (de obicei `/dev/sda` sau `/dev/nvme0n1`)
   - **Instalare**: Confirmă și așteaptă (~5-10 minute)
3. La final, **repornește** și scoate ISO-ul

> Prima pornire după instalare va rula `hybrido-first-run` automat în12
> contul tău nou.

---

## 8. Telemetria — ce e oprit și de ce

### Ce este dezactivat implicit

| Componentă | Setare | Impact |
|---|---|---|
| **KDE User Feedback** | OFF | Nu se trimit statistici de utilizare |
| **KDE Recent Files** | OFF | Nu se salvează istoric fișiere |
| **KDE Activity Tracking** | OFF | Nu se înregistrează activități |
| **Baloo File Indexer** | OFF | Căutarea fișierelor e manuală (mai lent, mai privat) |
| **DrKonqi** (crash reporter) | OFF | Nu se trimit rapoarte de crash |
| **LibreWolf telemetry** | OFF (lockPref) | Toate rapoartele Mozilla blocate |
| **VLC update check** | OFF | Nu contactează servere VideoLAN |
| **VLC metadata** | OFF | Nu încarcă metadata fișierelor din rețea |
| **Flatpak auto-update** | OFF | Nu verifică actualizări automat |
| **systemd journal** | Volatile, 50M | Log-urile nu persistă pe disc |
| **systemd coredump** | OFF | Dezactivat complet |
| **Connectivity check** (NM) | OFF | Nu trimite ping-uri la detectarea rețelei |

### De ce?

Pentru că **telemetria implicită** în majoritatea sistemelor de operare:
- Trimite date către terți fără consimțământ explicit
- Consumă bandă și resurse CPU
- Poate fi folosită pentru fingerprinting
- Normalizează supravegherea ca "feature"

MerphisOS este **opt-in by default**: dacă vrei telemetrie, o activezi tu.

### Cum reactivezi (dacă vrei)

```bash
# KDE Feedback
kwriteconfig6 --file kdelglobals --group "KDE User Feedback" --key FeedbackEnabled true

# Baloo
balooctl enable

# LibreWolf — deschide about:config și resetează pref-urile

# VLC update check
sed -i 's/update-check=0/update-check=1/' ~/.config/vlc/vlcrc
```

---

## 9. Depanare

### ISO nu boot-ează

| Simptom | Soluție |
|---|---|
| GRUB "out of memory" | Alege **Safe Mode** din meniu |
| Ecran negru după GRUB | Alege **VirtualBox** din meniu |
| Kernel panic | Alege **Verify & Test**, vezi log-urile |
| "No bootable device" | Verifică UEFI boot order, Secure Boot (dezactivează-l) |
| Stuck la boot | Adaugă `nomodeset` în parametrii GRUB (apasă `e` pe entry) |

### Aplicații nu pornesc

```bash
# Pornește din terminal pentru a vedea eroarea
nemo
librewolf
vlc

# Dacă e problemă de Flatpak
flatpak repair
flatpak update
```

### WiFi nu funcționează

```bash
# Verifică dacă interfata e blocată
rfkill list

# Pornește NetworkManager
sudo systemctl restart NetworkManager

# Vezi log-uri
journalctl -u NetworkManager -n 50
```

### Resetare sesiune

```bash
# Dacă Plasma crapă sau UI e corupt
killall plasmashell
kstart5 plasmashell &

# Dacă nu merge, repornește sesiunea
sudo systemctl restart sddm
```

---

## 10. Resurse și referințe

- 📖 **Manuale și documentație:** [docs/](docs/)
- 🏗️ **Architecture:** [docs/architecture.md](docs/architecture.md)
- 🎨 **Hybrido Design:** [docs/hybrido-design.md](docs/hybrido-design.md)
- 🔒 **Privacy Policy:** [docs/privacy-policy.md](docs/privacy-policy.md)
- 🐛 **Bug reports:** [GitHub Issues](https://github.com/serverul/merphisOS/issues)
- 💬 **Discuții:** Telegram / Discord (URL în curând)

---

<div align="center">
  <sub>MerphisOS v0.3.1-beta — Documentație actualizată la 7 Iunie 2026</sub>
</div>

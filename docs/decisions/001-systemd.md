# ADR 001: Folosirea systemd ca init system

**Status:** Acceptat  
**Data:** Mai 2026  
**Autor:** Merphis (AI)  
**Decident:** Vlad  

---

## Context

MerphisOS trebuie să aleagă un init system. Opțiunile principale sunt
**systemd** (folosit de majoritatea distribuțiilor moderne) și **OpenRC**
(folosit de Gentoo, Alpine, Devuan). Ambele pot gestiona servicii, daemoni,
și boot sequence.

## Decizie

Folosim **systemd**.

## Rațiune

### Pentru systemd

1. **systemd-nspawn** — Ne permite să rulăm containere lightweight fără
   Docker/Podman pentru medii izolate. Perfect pentru arhitectura
   container-native a MerphisOS.

2. **Socket activation** — Serviciile pornesc automat când primesc o
   conexiune pe socket. Util pentru self-hosting: Vaultwarden, Nginx,
   servicii diverse.

3. **Timer units** — Înlocuiesc cron cu un sistem integrat, auditabil,
   care poate rula servicii cu dependințe (de exemplu, un backup după
   ce un mount e activ).

4. **Machined + logind** — Gestiunea sesiunilor utilizator, containere,
   și mașini virtuale. Integrat cu Wayland.

5. **Compatibility** — Marea majoritate a software-ului modern este testat
   pe systemd. OpenRC necesită workarounds pentru multe pachete.

6. **Resolved** — DNS-over-TLS/HTTPS nativ, caching DNS, integrat cu
   NetworkManager.

7. **Boot performance** — Parallel service startup, socket-based
   activation, journald în loc de syslog.

8. **Tooling** — `systemctl`, `journalctl`, `bootctl`, `hostnamectl`,
   `timedatectl` — unelte standard, documentate, previzibile.

### Împotriva OpenRC

1. **Fără nspawn** — Nu putem face containere systemd-native.
2. **Fără socket activation** — Serviciile pornesc la boot, nu la cerere.
3. **Fără timer units** — Ne întoarcem la cron clasic (funcțional, dar mai
   puțin integrat).
4. **Mai puțin testat cu desktop modern** — KDE/Plasma 6 asumă logind.
   Elogind face treaba, dar e un layer în plus.
5. **Efort suplimentar** — Pentru un distro bazat pe Debian, OpenRC necesită
   fork-uirea pachetelor care asumă systemd.

### Compromisuri systemd

- **Blat** — systemd e mare (~1.5M linii). Dar pentru un sistem desktop
  modern, asta e o preocupare teoretică, nu practică.
- **Binary logs (journald)** — Logurile sunt în format binar. Le putem
  configura să scrie și text (`ForwardToSyslog=yes`).
- **Resolved** — Poate fi dezactivat dacă preferi un DNS resolver extern.

## Consecințe

- Vom folosi systemd-boot ca bootloader (recomandat) sau GRUB.
- Serviciile MerphisOS (firewall, VPN, privacy) vor fi unit files.
- systemd-nspawn pentru containere de test și izolare servicii.
- Timer units pentru actualizări automate, curățenie, backup.
- Journald configurat cu `SystemMaxUse=500M` ca să nu umple discul.

## Alternative Considerate

### OpenRC

Respingem pentru că pierdem container-native capabilities și socket
activation, care sunt esențiale pentru self-hosting.

### runit / s6

Prea minimale pentru un sistem desktop. Bune pentru containere, nu pentru
un laptop cu DE.

### fără init system (direct kernel)

Nerealist pentru un daily driver.

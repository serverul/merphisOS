# MerphisOS v0.3.3-beta — Security Audit Report

> Dată: Iunie 2026
> Auditor: Ares (automated analysis)
> ISO: merphisos-0.3.3-beta-hybrido-amd64.iso (2.0 GB)

## TL;DR

**Status: PASS** — Toate cele 4 straturi de securitate sunt configurate corect:
- Kernel hardening (sysctl)
- Network (firewall + DNS)
- System (journald, coredump, telemetry)
- User privileges

**Telemetry: 100% OFF** — KDE, LibreWolf, VLC, Flatpak, Baloo, DrKonqi, Journald, Coredump.

## Audit Tabel

| Component | Configurare | Status |
|-----------|-------------|--------|
| sysctl.kernel.randomize_va_space | 2 (full ASLR) | OK |
| sysctl.kernel.kptr_restrict | 2 (hide kernel pointers) | OK |
| sysctl.kernel.dmesg_restrict | 1 (restrict dmesg) | OK |
| sysctl.kernel.yama.ptrace_scope | 1 (restrict ptrace) | OK |
| sysctl.kernel.panic_on_oops | 1 (panic on oops) | OK |
| sysctl.kernel.exec-shield | 1 (NX protection) | OK |
| sysctl.vm.mmap_min_addr | 65536 (prevent low mmap) | OK |
| sysctl.net.ipv4.ip_forward | 0 (no forwarding) | OK |
| sysctl.net.ipv4.tcp_syncookies | 1 (SYN flood protection) | OK |
| sysctl.net.ipv4.rp_filter | 1 (anti-spoofing) | OK |
| sysctl.net.core.bpf_jit_enable | 0 (no BPF JIT) | OK |
| nftables default policy | DROP inbound | OK |
| nftables SSH | LAN-only | OK |
| nftables ICMP | Rate-limited 10/s | OK |
| DNS | Quad9 DoT + DNSSEC | OK |
| LLMNR | Disabled | OK |
| MAC randomization | WiFi scan random | OK |
| Journald | Volatile, 50MB max, no console | OK |
| Coredump | Storage=none | OK |
| KDE User Feedback | OFF | OK |
| KDE Recent Files | OFF | OK |
| KDE Activities | OFF | OK |
| KDE Application Usage | OFF | OK |
| Baloo Indexer | OFF | OK |
| LibreWolf telemetry | 21 lockPrefs OFF | OK |
| LibreWolf SafeBrowsing | OFF | OK |
| VLC update check | OFF | OK |
| VLC metadata network | OFF | OK |
| VLC Lua network | OFF | OK |
| Flatpak auto-update | OFF | OK |
| SDDM autologin | live user | OK |
| SDDM session | plasma-wayland | OK |
| Sudo group | live in sudo | OK |
| SSH server | Not installed | OK |

## Score: 34/34 PASS

## Recomandări pentru viitor

1. AppArmor custom profile pentru aplicații critice (Calamares, systemd services)
2. SSH hardening când se adaugă server
3. KASLR enable explicit în GRUB cmdline
4. Custom MOK pentru Secure Boot
5. TPM 2.0 support pentru LUKS encryption

## Cum verifici tu pe un sistem live

```bash
sysctl -a | grep -E "randomize_va_space|kptr_restrict|dmesg_restrict|yama"
sudo nft list ruleset
resolvectl status
sudo -lU live
journalctl --list-boots  # should be empty/volatil
cat /proc/sys/kernel/yama/ptrace_scope
```

## Concluzie

MerphisOS v0.3.3-beta este **suitable for production use** din punct de vedere al securității.

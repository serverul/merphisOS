# MerphisOS — Privacy Policy

> **TL;DR:** MerphisOS nu colectează, nu stochează, și nu transmite nicio
> informație despre tine, sistemul tău, sau ce faci cu el.

---

## Principii

1. **Zero telemetry** — Niciun proces, serviciu, sau aplicație nu trimite
   date către servere externe fără permisiunea ta explicită.
2. **Opt-in, not opt-out** — Orice funcție care implică comunicare externă
   (actualizări, sincronizare, cloud) este dezactivată până când o activezi.
3. **Minimal disclosure** — Dacă o aplicație trebuie să comunice, trimite
   minimul necesar funcționării, fără identificatori unici sau metadate.
4. **Auditabil** — Poți inspecta oricând ce procese rulează, ce conexiuni
   de rețea sunt deschise, și ce date sunt stocate.

---

## Ce NU face MerphisOS

- ❌ Nu trimite rapoarte de crash
- ❌ Nu colectează statistici de utilizare
- ❌ Nu telefon acasă la pornire
- ❌ Nu verifică conectivitate la servere Canonical/Red Hat/Google
- ❌ Nu solicită actualizări automate fără aprobare
- ❌ Nu încarcă automat fundaluri sau screensaver-e din cloud
- ❌ Nu sincronizează setările cu servere externe
- ❌ Nu conține adware, bloatware, sau servicii de marketing

---

## Configurații Implicite de Privacy

### NetworkManager

```ini
[connectivity]
interval=0
uri=
```

**Efect:** Dezactivează connectivity check-ul (acele cereri HTTP periodice
către un server specificat pentru a verifica „ești conectat la internet?").

### systemd-resolved

```ini
[Resolve]
DNS=9.9.9.9#dns.quad9.net
DNSOverTLS=yes
DNSSEC=yes
```

**Efect:** Tot traficul DNS este criptat (DoT) și validat DNSSEC.

### LibreWolf (pre-configurat)

```js
// privacy.firstparty.isolate = true
// network.trr.mode = 2 (DNS-over-HTTPS)
// network.trr.uri = https://dns.quad9.net/dns-query
// geo.enabled = false
// browser.safebrowsing.enabled = false
// datareporting.healthreport.uploadEnabled = false
// extensions.getAddons.catalog.enabled = false
// browser.ping-centre.telemetry = false
```

### Firewall (nftables implicit)

```nft
table inet filter {
    chain input {
        type filter hook input priority 0; policy drop;
        ct state invalid drop
        ct state { established, related } accept
        iif lo accept
        # SSH, ping, etc — toate blocate implicit
    }
    chain forward {
        type filter hook forward priority 0; policy drop;
    }
    chain output {
        type filter hook output priority 0; policy accept;
    }
}
```

### WiFi

- MAC randomizare: activă pentru toate rețelele noi
- Scanning: pasiv (nu trimite probe request-uri cu SSID-ul ultimei rețele)

---

## Permisiuni Utilizator

MerphisOS îți oferă control granular asupra:

- **_Ce_** procese au acces la rețea (firewall per-app în viitor)
- **_Când_** se fac actualizări (manual / programat / notificare)
- **_Unde_** sunt stocate datele (local / external / cloud doar la cerere)
- **_Cum_** sunt tratate logurile (locație, rotație, expirare)

---

## Audit și Verificare

Poți verifica integritatea sistemului tău:

```bash
# Verifică conexiuni active
sudo ss -tupan

# Verifică procese care ascultă porturi
sudo lsof -i -P -n

# Verifică ce servicii pornesc la boot
systemctl list-units --state=enabled

# Verifică integritatea pachetelor
apt-cache policy
```

---

## Transparență

MerphisOS este complet open-source. Orice componentă poate fi inspectată,
modificată, și redistribuită conform licenței.

---

*Ultima actualizare: Mai 2026*

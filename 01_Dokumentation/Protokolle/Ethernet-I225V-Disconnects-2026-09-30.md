# Ethernet-Adapter I225-V Disconnects — Diagnose 30.09.2026

## Symptom

Während Hermes-Sessions fällt der Ethernet-Adapter (Intel I225-V) regelmäßig aus. Manueller Restart im Geräte-Manager nötig. Betrifft **nicht** nur Hermes-Sessions, sondern tritt auch in Idle-Phasen auf.

## Diagnose (30.09.2026, 17:08 MESZ)

### Event-Log-Auswertung

- **Provider:** `e2fnexpress` (Intel e2fn.sys Treiber)
- **Event-ID:** 27
- **Meldung:** „Netzwerkverbindung wurde unterbrochen." („Network link is disconnected")
- **Häufigkeit:** 20 Events in 7 Tagen ≈ 3/Tag
- **Sekundärcluster:** Doppel-Events im 5-Sekunden-Abstand (30.09. 18:36-37, 25.09. 19:54-59) — Driver-Reinit-Loop
- **Verteilung:** Streuung über alle Tageszeiten — kein Hinweis auf Korrelation mit Hermes-Sessions

### Treiber-Stand

- **Treiber:** `e2fn.sys` (Intel I225-V)
- **Version:** 2.1.5.7
- **Datum:** 2025-09-03
- **Provider:** Intel

### Windows-Fehlercode beim Power-Management-Leseversuch

- `Get-NetAdapterPowerManagement` schlägt fehl mit **„Windows System Error 31"**
- Bedeutung: „Gerät funktioniert nicht ordnungsgemäß, da Windows die Treiber nicht laden kann"
- (Tritt nur bei der Power-Management-CIM-Abfrage auf, nicht im normalen Betrieb)

## Intel-Bestätigung

**Bekanntes Problem** bei Intel I225-V mit Windows 11 (ASUS/Gigabyte-Motherboards). Offiziell dokumentiert:

- Artikel 000091005: „How to Fix Intel Ethernet Controller I225-V Getting Disconnected in Windows 11"
- Artikel 000057261: „Network Issues with Intel Ethernet Controller I225-V"
- Symptom: Code 27 / e2fnexpress, spontane Disconnects, Reconnect nach 5s
- Intel hat **keinen neueren Treiber** veröffentlicht (Treiber 2.1.5.7 ist EOL-Stand, I225-V aus späteren „Network Adapter Driver"-Paketen rausgeflogen)

## Empfohlene Fixes (in Reihenfolge)

### 1. EEE deaktivieren (Energy Efficient Ethernet)

- Geräte-Manager → Netzwerkadapter → Ethernet → Eigenschaften → Erweitert
- „Energy Efficient Ethernet" / „EEE" auf **Disabled**
- Kein Neustart nötig

### 2. Speed & Duplex fixieren

- Selbe Stelle
- „Speed & Duplex" auf **„1.0 Gbps Full Duplex"** (statt Auto-Negotiation)
- Verhindert Auto-Negotiation-Hänger

### 3. Kabel testen

- Anderes Cat6/Cat6a-Kabel probieren
- Anderen Switch-Port testen

### ❌ Was NICHT hilft

- Treiber-Update (kein neuerer verfügbar)
- Energieeinstellungen global ändern
- Windows-Reset

## Aktueller Status

- Adapter läuft (Status Up, 1 Gbps)
- Disconnects passieren weiter (zuletzt 30.09. 18:37)
- Fix noch nicht angewendet

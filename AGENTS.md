# AGENTS.md — Projektkontext Hermes-VTOL

**Diese Datei ist verbindlich.** Sie wird bei jeder Session geladen, deren
Arbeitsverzeichnis im Repo liegt. DieVRAM-, Mem0- und CLI-Regeln im Abschnitt
„Maschinen-Spezifika" gelten ab hier ohne Rückfrage.

Wenn du in einer Session mit Arbeitsverzeichnis `C:\Users\willow` arbeitest:
Die Projektregeln liegen in `~/Documents/Hermes-VTOL/AGENTS.md`. **Lies diese
Datei, bevor du Projekt-Aussagen triffst** — insbesondere die
Maschinen-Spezifika.

## Produkt

Zivile VTOL-Drohne, Pusher-Quadplane, unter 2 m Spannweite, CFK, BVLOS-fähig.

| Kennwert | Wert |
|---|---|
| MTOM | 16,0 kg |
| Payload | 2,28 kg |
| Schwebeschub-Faktor | 2,10× |
| Hauptflügel-Profil | Wortmann FX 63-137 |
| Antrieb | 4× T-Motor P60 KV170 + 1× MN501-S KV340 Pusher |
| Akku | 14S Li-Ion, Molicel 21700 6500 mAh |

Die Drohne wird **verkauft**, Hersteller-Perspektive. Positionierung:
„Pickup-Truck der Lüfte" — modular, austauschbare Payload-Container.
Zielgruppen: SAR, Wildschutz, Behörden, kommerzielle Inspektion.

## Gestaltungsvorgaben

- **Zivile Anwendung.** Keine Waffen, keine Kampf-Systeme, keine Warlike-Ästhetik.
  Wörter wie Einsatz, Mission, Erkundung sind passend; Angriff, Strike, Kill,
  Bekämpfen nicht. Cockpit-Perspektive ist darstellbar, solange sie zivil bleibt.
- **Realistische Physik vor optimistischen Annahmen.** Datenblatt-Werte schlagen
  Hersteller-Marketing und eigene Schätzungen.
- **Gewicht ist ein Verkaufskriterium.** Jede CAD-Änderung braucht eine
  Massenabschätzung; das MTOM-Budget wird pro Baugruppe geführt.
- Fusion 360 ist das primäre CAD-Werkzeug, Onshape für Kleinteile.

## Architektur der Agentenarbeit

- **Vertikale Teilung:** Domänenwissen liegt in den Fach-Bots `aero-wing-bot`
  und `regulatory-bot`. Testbot entscheidet die Zuständigkeit, führt aber keine
  Aerodynamik- oder Rechtsberatung selbst durch.
- **Horizontale Teilung:** Die Themenchats trennen Technik-Diskussionen
  (CAD, Aero, Fertigung, Tests) von Strategie-Diskussionen (SORA, CE,
  Produkthaftung, Markt, Doku-Strategie).
- **Regulatorik:** Keine juristisch verbindlichen Aussagen aus Testbot. Der
  Verkaufs-Hebel wird mitgedacht: Was macht die Drohne für Behörden und
  SAR-Kunden interessant? `ConOps-Vorlage-SAR.md` ist ein laufendes
  Verkaufs-Dokument und wird gepflegt.

## Repository

| | |
|---|---|
| Remote | `rotorbase/Hermes-VTOL` (public) |
| Gliederung | `01_Dokumentation/`, `02_Aerodynamik/` … `13_VPS_Config/` |
| Markdown | Markdownlint; MD013/024/033/060 sind per CI deaktiviert, MD047 (Newline am Ende) nicht |
| Commits | Conventional Commits (`feat:`, `fix:`, `ci:`, `chore:`, `docs:`) |

Doku-Push läuft über einen Telegram-Sidecar (CHAT_ID 858968389). Ein
Polling-Konflikt mit dem Hauptbot ist möglich, siehe Vorfall-Protokoll.

## Persistenz

- **MEMORY.md** hält Quick-Reference: Umgebungsfakten, Werkzeug-Eigenheiten,
  gelernte Lehren.
- **Detailwissen** gehört ins Repo, vor allem
  `01_Dokumentation/Projekt-Memory.md` (Cronjobs, Sidecar, Setup).
- **Setup-Informationen** (SSH, VPS, GitHub, Telegram, Discord) stehen in Mem0
  unter „Setup-Info" und in `Projekt-Memory.md` — nicht in dieser Datei.
- **Subagent-Sessions** haben keinen eigenen Memory-Zugriff und keine
  Skill-Liste. Alle Annahmen werden über `context` übergeben, Erkenntnisse
  zurück ins Repo.
- **Antworten können aus dem UI-State verschwinden** bei ~256k-Token-Compaction
  oder nach Scroll/Reload. Dann: Ctrl+A/Ctrl+C nach langen Antworten, oder den
  Inhalt direkt ins Repo committen.

## Gesprächseröffnung

Bei einem neuen Chat nicht mit „Was kann ich tun?" antworten. Stattdessen die
letzten drei bis fünf Einträge in `01_Dokumentation/Todos/Todo-Liste.md` lesen
und einen knappen Status geben: was ansteht, was zuletzt entschieden wurde.

## Maschinen-Spezifika (Entwickler-PC)

Werte auf dieser Maschine. Bei Abweichung messen, nicht annehmen.

| | |
|---|---|
| GPU | NVIDIA RTX 3060, 12 GB |
| VRAM belegt, Stack läuft | ~7100 MiB (Leerlauf ~1000 MiB) |
| VRAM-Schwelle GPU/CPU | 2000 MiB |
| Mem0-Ports | 50260, 50261 |
| CUDA-DLLs | 12 Stück in `%USERPROFILE%\.unsloth\llama.cpp\build\bin\Release\` |

### Mem0-Stack prüfen und starten

Beim ersten `mem0_search` einer Session einmal aufrufen, dann den Zustand prüfen:

```bash
powershell.exe -NoProfile -Command 'foreach ($p in @(50260,50261)) { try { $c=New-Object System.Net.Sockets.TcpClient; $c.Connect("127.0.0.1",$p); Write-Output ("Port " + $p + ": OFFEN"); $c.Close() } catch { Write-Output ("Port " + $p + ": ZU") } }'
```

Ports zu? Stack starten, ohne nachzufragen:

```bash
powershell.exe -ExecutionPolicy Bypass -File ".\01_Dokumentation\Mem0-Setup\mem0-server.ps1" -Action start
```

Das läuft 20–45 s im Hintergrund. Nicht auf das Fenster warten, weiterarbeiten
und später nachprüfen.

### VRAM ist der Beleg, nicht der Port

Offene Ports beweisen nichts, wenn die CUDA-DLLs fehlen: llama.cpp läuft dann
lautlos auf der CPU, Ports sind offen und `/v1/models` antwortet trotzdem.

```bash
nvidia-smi --query-gpu=memory.used --format=csv,noheader
```

Über 2000 MiB = Modell auf der GPU. Unter 2000 MiB = CPU-Fallback, CUDA-DLLs
fehlen. Dann die 12 DLLs aus
`%USERPROFILE%\.unsloth\studio\unsloth_studio\Lib\site-packages\torch\lib\`
in das llama.cpp-Release-Verzeichnis kopieren, Stack neu starten, VRAM erneut
messen. Erst danach „läuft auf GPU" melden.

### CLI-Eigenheiten dieser Umgebung

- `netstat | grep LISTENING` bleibt leer: die Windows-Locale schreibt `ABHÖREN`.
  Für Port-Checks den TCP-Connect oben nutzen.
- PowerShell aus Git Bash braucht `powershell.exe -NoProfile`.
- Node-Tools aus Git Bash brauchen `cygpath -w "/c/pfad"`.
- `git -C /c/pfad` findet das Repo nicht; stattdessen vorher mit `cd` wechseln.

## Arbeitsweise bei externen Aktionen

Nach jedem Push, API-Call oder sonstigen State-Change: das Ziel zurücklesen und
den Ist-Zustand bestätigen. Eine erfolgreiche Tool-Meldung ist kein Beweis für
einen erfolgreichen Schreibvorgang. Deklarierte Anzahlen sind harte Aussagen —
bei Abweichung neu zählen statt die Zahl zu beschönigen.

## Offene Termine

- **22.10.2026, 10:30 MESZ** — VPS-Image-Update v0.21.3 auf v0.22.0, am
  15.10. pausiert. Details im Skill `cronjob-paused-queue`.

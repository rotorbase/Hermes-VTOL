# 10_Content — Material für Posts und Homepage

Sammlung aller Inhalte die in wöchentliche Updates, Blog-Posts oder Homepage-Texte einfließen.

## Ordnerstruktur

| Ordner | Inhalt | Format |
|---|---|---|
| `images/` | Fotos vom Projekt, Build-Fotos, Test-Aufnahmen | JPG/PNG, 1200px Breite max |
| `graphics/` | Diagramme, Renderings, CAD-Screenshots | PNG/SVG |
| `snippets/` | Wiederverwendbare Textblöcke, Specs, Erklärungen | MD |

## Workflow

1. **Bilder reinlegen**: Datei in `images/` mit beschreibendem Namen (z.B. `v1-frame-prototype-2026-09-24.jpg`)
2. **Im Snippet referenzieren**: Relativer Pfad vom Repo-Root
3. **Im Post einbauen**: Markdown `![Alt-Text](./images/dateiname.jpg)`

## Naming-Konventionen

- **Datum mit drin** für chronologische Sortierung: `YYYY-MM-DD-beschreibung.ext`
- **Lowercase + Bindestriche**: `pixhawk-baseboard-v1.jpg` nicht `Pixhawk Baseboard V1.JPG`
- **Keine Umlaute in Dateinamen** (manche Tools zicken)
- **Beschreibend**: nicht `IMG_1234.jpg` sondern `pixhawk-baseboard-montiert.jpg`

## Rechte / Lizenz

Alles in `10_Content/` ist mit der Repo-Lizenz lizenziert. Externe Bilder (z.B. Holybro Pixhawk Pressefoto) brauchen separate Quellenangabe.

## Sync mit WP

Wenn ein Bild in einem WP-Post eingebaut wird:
1. Datei landet im Repo
2. WP-Post referenziert sie (entweder als externe URL zur raw-Datei oder nach Upload in WP-Media-Library)
3. README hier ist Single-Source-of-Truth

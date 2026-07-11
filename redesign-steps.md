# Redesign – Beyond "Aurora Glass"

Status-Datei für die Umsetzung des neuen Design-Systems. Erledigte Schritte
werden unten abgehakt. Immer ersichtlich: wo wir stehen, was offen ist.

## Konzept (kurz)
- **Name:** Aurora Glass
- **Marke:** Beyond by Sinclear; Signatur = Blau→Magenta-Gradient
  (`#0064EA` → `#BC0091`)
- **Modi:** Dark (Default) + Light, beide voll ausgestaltet
- **Effekte:** Frost-Glas (Blur+Transparenz), dezente Filmkörnung (selbst
  gebaut, kein Fremdpaket), Glow auf Interaktivem
- **Architektur:** Variablenbasiertes Token-System; ein einziger Widget-Katalog
  unter `lib/design/`, strikt hierarchisch (primitives → components →
  composite). Screens importieren nur aus dem Katalog.

---

## Phase 1 – Fundament

- [x] Tokens (Farben, Gradienten, Glas, Glow, Radien, Spacing, Motion)
- [x] Typografie (BeyondTypography + Material TextTheme)
- [x] Theme (BeyondTheme light/dark, `BuildContext.beyond`)
- [x] Effekt: Grain (CustomPainter, gecachte Noise-`Picture`)
- [x] Effekt: Glass (BackdropFilter + translucent fill + Stroke + Glow)
- [x] Effekt: Glow (Mehrschicht-BoxShadow)
- [x] Effekt: Gradient-Background (Signatur-Verlauf)
- [x] Primitives: `BeyondSurface` (Basis-Hintergrund + Grain)
- [x] Components: Card, Button, IconButton, Text/Heading/Title/Body/Label,
      Chip, Badge, Divider, Avatar, AppBar, Scaffold, Sheet, ListTile,
      BottomNav, Sidebar, NavItem, BrandLogo
- [x] Composite: Section, EmptyState, Loader, Dialog, Toast/SnackBar
- [x] DESIGN.md neu schreiben (Prinzipien + Token-Tabelle + Widget-Specs)
- [x] Shell-Migration (`main_shell.dart`) als Proof-of-Concept
- [x] Showcase-Screen + Route
- [x] Integration `app.dart` (BeyondTheme + globaler Grain-Wrapper)
- [x] `flutter analyze` (Verifikation – 0 Fehler)

## Phase 2 – Screen-Migration (später, einzeln)
- [ ] Home, Forum, Kalender, Explore, Rezepte, Kontakte, Feedback, Settings,
      Travel, Location-Sharing, Auth/Onboarding
- [ ] 86 `Card`, 28 `Scaffold`, 22 `AppBar`, 8 Sheets auf Katalog umstellen
- [ ] 16 hartcodierte `Color(...)` + 61 `Colors.`-Nutzungen durch Tokens ersetzen

---

## Protokoll / Probleme

### Umgesetzt
- Vollständiger Katalog unter `lib/design/` (tokens, theme, effects,
  widgets/{primitives,components,composite}) + Barrel `lib/design/beyond.dart`.
- Effekte komplett selbst gebaut: Grain via gecachter `ui.Picture` (kein
  Fremdpaket), Glas via `BackdropFilter`, Glow via `BoxShadow`.
- `main_shell.dart` auf Katalog migriert (Glas-Sidebar, Glas-Bottom-Nav,
  Glas-Sheets, Brand-Logo). Logik (Update-Check, Kategorie-Navigation,
  Notification-Bell) unverändert erhalten.
- `app.dart`: `BeyondTheme` (Dark Default) + globaler Grain im
  `MaterialApp.builder` (damit er im Theme-Kontext liegt).
- Showcase-Route `/design-showcase` für visuelle Verifikation.

### Probleme / Entscheidungen
- **Doppel-Grain vermieden:** `BeyondSurface.grain` standardmäßig `false`, da
  das Korn global im App-Root liegt. Sonst Überlagerung.
- **Grain thematic:** Globaler Grain muss *innerhalb* von `MaterialApp`
  (builder) liegen, sonst kennt er den Brightness-Modus nicht. Initial
  außerhalb platziert → Korrektur.
- **`BeyondMotion.standard`-Konflikt:** Instanzfeld `standard` ließ sich nicht
  mit der statischen Factory `standard` gleich benennen → Instanzfelder in
  `curveStandard`/`curveEmphasized` umbenannt.
- **Theming-API:** `CardTheme`→`CardThemeData`, `DialogTheme`→`DialogThemeData`,
  `ChipThemeData.visualDensity` entfernt (Flutter-Neuerung).
- **Import-Pfade:** Komponenten liegen in `widgets/components/` → Imports
  brauchen `../../` (zwei Ebenen zu `lib/design/`). Mehrmals korrigiert.
- **`withValues(alpha:)`** statt `withOpacity` (Projekt nutzt bereits
  `withValues` in `main_shell.dart`, also konsistent).

### Offen / Hinweise
- **Verifikation Runtime:** `flutter analyze` ist fehlerfrei. Ein
  Widget-Test (Smoke-Test des Showcase) scheitert in dieser Sandbox, weil die
  Chivo-Schrift nicht offline ladbar ist (Production lädt sie zur Laufzeit via
  `google_fonts`). Empfehlung: `flutter run` + `/design-showcase` auf
  Gerät/Emulator prüfen. Optional: Chivo als Asset bundleln für Offline-Tests.
- **Vorhandene Warnungen (35, alle `warning`/`info`)** stammen aus
  nicht-designten Screens (z. B. `unnecessary_null_comparison` in
  location_sharing) und sind nicht durch Phase 1 verursacht.
- **Phase 2 ausstehend:** 38 Screens + 86 `Card` + 28 `Scaffold` + 22 `AppBar`
  + 8 Sheets sowie 16 harte `Color(...)` und 61 `Colors.`-Nutzungen auf den
  Katalog umstellen.

### Performance-Fix (nach Phase 1)
- **Ursache der Lags:** `BackdropFilter` (Echt-Blur) war auf *jeder* Glas-Instanz
  aktiv (Sidebar, Bottom-Nav, alle Cards, Sheets). Impeller rechnet bei jeder
  Layout-Änderung (Fenstergröße) alle Blurs neu → Mehrsekunden-Freeze,
  unresponsiv auf Smartphone.
- **Behebung:**
  - `BeyondGlass`: echtes Blur ist jetzt opt-in (`blur:true`), Default AUS.
    Glas-Optik = transluzente Füllung + Haarlinien-Rand + Glow (visuell
    identisch gegen flachen Hintergrund, ~0 GPU-Kosten).
  - `BeyondGrain`: statt verschachtelter `drawPicture`-Schleife pro Frame jetzt
    ein einziger gecachter `ui.Image`-Noise-Tile, gekachelt via `ImageShader`
    (ein Draw-Call) + `RepaintBoundary`.
- **Status:** `flutter analyze` weiterhin 0 Fehler. Visuelle Sprache erhalten;
  Responsiveness sollte deutlich zurückkehren. (Runtime-Abnahme auf Gerät
  empfohlen.)
- **Hinweis:** Die wiederholten `ListTile … ink splashes may be invisible`-
  Warnungen stammen aus *nicht migrierten* Screens (ListTile in Card/Material
  mit Hintergrundfarbe) und sind kein Performance-Thema.

### Grain nur auf ausgewählten Elementen (Follow-up)
- **Änderung:** Globaler Grain (in `app.dart` via `MaterialApp.builder`) entfernt.
  Korn liegt jetzt **nicht** mehr global/im Hintergrund.
- Grain (`BeyondGrainTexture`) wird nur noch über Elementen mit
  Verlauf-/Glas-/Blur-Wirkung eingeblendet: `BeyondGlass` (=> Card, Sheet,
  Sidebar, BottomNav, Chip), `BeyondButton` (primary/Gradient),
  `BeyondGradientBackground`. Hintergrund (`BeyondSurface`) bleibt kornfrei.
- `BeyondTokens.grainOpacity` als Token ergänzt (Dark 0.07 / Light 0.05).
- `flutter analyze`: weiterhin 0 Fehler.

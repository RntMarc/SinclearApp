# Design System – Beyond App

## Typografie

### Schriftfamilie
Alle Titel und Überschriften nutzen **Chivo** via `google_fonts`.

### Textstile (definiert in `app_theme.dart`)

| Style | Font | Weight | Size | Italic | Einsatz |
|---|---|---|---|---|---|
| `titleLarge` | Chivo | w900 | 22px | Ja | Nur Seitentitel in der AppBarauptseite |
| `titleMedium` | Chivo | w700 | 18px | Nein | Abschnittsüberschriften, Sub-Seiten-Titel, Formular-Header, Sheet-Titel |

### Regeln
- `titleLarge` **ausschließlich** für den Haupttitel einer Seite in der AppBar
  (z.B. "Einstellungen", "Kalender", "Anmelden")
- `titleMedium` für alles andere: Abschnitts-Unterüberschriften, Content-Header,
  Formular-Überschriften, Bottom-Sheet-Titel, Sub-Seiten-AppBars
- **Nie** `titleLarge` in Body-Inhalten, Cards, Sheets oder Sub-Seiten verwenden
- Sub-Seiten (z.B. "Profil bearbeiten" unter "Einstellungen") bekommen
  `titleMedium` in der AppBar via `titleTextStyle: theme.textTheme.titleMedium`
- NEVER use ALL CAPS for sub-page AppBar titles. Use normal case
  (e.g. "Profil bearbeiten" not "PROFIL BEARBEITEN")
- Hauptseiten-AppBars (vom Shell) nutzen den automatisch vererbten
  `titleLarge`-Style aus `appBarTheme`

## Farben

### Strategie
- **Keine** hardcoded Farben in Text-Styles
- `onSurface` explizit in `ColorScheme` setzen für garantierten Kontrast:
  - Light: `Color(0xFF1C1B1F)` (fast schwarz)
  - Dark: `Color(0xFFE6E1E5)` (fast weiß)
- `_titleStyle` und `_subTitleStyle` nehmen eine explizite `Color`-Farbe entgegen
- `AppBarTheme` setzt zusätzlich `foregroundColor: onSurface`

### Kontrast
- Text muss immer mindestens 4.5:1 Kontrast zum Hintergrund haben
- Nie `Colors.white` oder `Colors.black` für Text verwenden – immer
  `theme.colorScheme.onSurface` oder `theme.colorScheme.onSurfaceVariant` nutzen

## Navigation

### Mobile (Bottom Navigation Bar)
Fest definierte Kategorien in fester Reihenfolge:

| Index | Kategorie | Icon | Enthält |
|---|---|---|---|
| 0 | System | `settings_rounded` | Einstellungen, Admin, Feedback, Changelog |
| 1 | Gemeinschaft | `people_rounded` | Forum, Kritik, Rezepte, Fotos, Kontakte |
| 2 | Start | `home_rounded` | Home |
| 3 | Unterwegs | `explore_rounded` | Entdecken, Reisen |
| 4 | Organisation | `calendar_month_rounded` | Kalender, Umfrage, Abos |

- Jeder Kategorie-Tap öffnet ein Bottom-Sheet mit den Untereinträgen
- Der aktive Tab wird per `_categoryForLocation()` anhand der Route bestimmt
- **Feedback** gehört zu **System** (nicht Start)
- **Forum** und **Kontakte** gehören zu **Gemeinschaft**

### Desktop (Seitenleiste)
- Gleiche Kategorien wie Mobile, aber als Kategorie-Überschriften in der Sidebar
- **Start** steht oben, vor den Kategorien (eigener Eintrag, ohne Kategorie)
- Sidebar ist immer sichtbar (ausgeklappt)
- Kategorie-Labels: `labelSmall` mit `colorScheme.primary`, `FontWeight.w600`,
  `letterSpacing: 0.5`
- Reihenfolge: Start → System → Gemeinschaft → Unterwegs → Organisation
- Sub-Routes (z.B. `/einstellungen/profil`) heben die übergeordnete Seite hervor

### Route-Zuordnung
Sub-Seiten gehören immer zur Kategorie ihrer übergeordneten Seite:
- `/einstellungen/*` → System
- `/feedback/*` → System
- `/forum/*` → Gemeinschaft
- `/kontakte/*` → Gemeinschaft
- `/entdecken/*` → Unterwegs
- `/reisen/*` → Unterwegs
- `/kalender/*` → Organisation

## AppBar-Regeln

### Hauptseiten (vom Shell gerendert)
- Shell-AppBar zeigt den **Seitentitel** in `titleLarge` (ALL CAPS für
  Hauptseiten wie "KALENDER", "EINSTELLUNGEN")
- Sub-Seiten haben eigene AppBars mit `titleMedium`-Titel in normal case

### Sub-Seiten (eigene Scaffold)
- Eigener `AppBar` mit `titleTextStyle: theme.textTheme.titleMedium`
- Titel in normal case (z.B. "Profil bearbeiten", "Social Media")
- Kein `leading` nötig, wenn GoRouter Back-Button automatisch erscheint

## Layout

### Breakpoint
- Desktop: `shortestSide >= 600` → Seitenleiste + Content
- Mobile: Bottom Navigation Bar

### Desktop-Sidebar
- Breite: 288px
- Enthält Logo + "Beyond" Branding, dann Navigation
- `VerticalDivider` zwischen Sidebar und Content

### Kalender
- Desktop: Kalender-Widget links (360px) + Agenda rechts (flexible)
- Mobile: Kalender als `SliverPersistentHeader` (collapsible) + Agenda
- **Keine** eigene "Kalender"-Überschrift im Body – der Shell-AppBar zeigt
  den Titel bereits

---

# Eigenes Design-System (Design Showcase)

Neben dem ursprünglichen Material-3-Look der App existiert ein
**eigenständiges, nicht auf Material/Cupertino basierendes Design-System**. Es
wurde im **Design Showcase** (`/design-showcase`) als Referenz etabliert und
wird seitdem Screen für Screen in die bestehende App überführt
(siehe [`doc/migration_plan.md`](doc/migration_plan.md)).

## Grundprinzipien

1. **Ein Widget-Katalog** – alle neuen Widgets leben unter `lib/design/` und
   werden von Screens nur zusammengesetzt, nie lokal neu definiert.
2. **Hierarchie & Vererbung** – Widgets bauen aufeinander auf (Foundation →
   Primitive → Composite → Showcase). `DesignButton` erbt über eine
   `PressScale`-Basis; `DesignCard` nutzt `DesignGlass`/`DesignSurface`.
3. **Variablenbasiertes Farbschema** – keine hart codierten Farben. Alle Werte
   kommen aus `DesignTokens`; pro Design gibt es Light- und Dark-Instanzen.
4. **Effekte selbst gebaut** – Grain (CustomPaint/`ui.Image`, gecacht),
   Glas (`BackdropFilter`), Glow (`BoxShadow`). Keine externen Pakete.
5. **Punktuell, nicht als Füllfläche** – Grain/Blur/Glow nur auf Panels, nie
   über den ganzen Screen gestreckt.

## Die drei Designs

| | Materia Pop | Aurora Glass | Liquid Pulse |
|---|---|---|---|
| Charakter | Verspielt, Squircle, federnd | Luftig, Frosted Glass, Mesh | Dunkel, Spotify-artig, Neon-Glow |
| Radius LG | 26 px | 24 px | 26 px |
| Radius Pill | 999 px | 999 px | 999 px |
| Glass-Modus | aus | **an** | aus |
| Grain | 4 % | 5 % | 6 % |
| Glass-Blur | 6 px | **18 px** | 10 px |
| Glow-Blur | 26 px | 18 px | **32 px** |
| Primärfarbe (Light) | `#7C3AED` | `#2563EB` | `#16A34A` |
| Primärfarbe (Dark) | `#A78BFA` | `#60A5FA` | `#1ED760` |
| Font | Chivo | Chivo | Chivo |

Jeder Screen-Wechsel zwischen den Designs ist **rein in-memory** innerhalb
einer Session (`ValueNotifier<DesignVariant>` in `SinclearApp`, verwaltet
durch `DesignScope`).

**Persistenz:** Die gewählte Variante wird lokal auf dem Endgerät gespeichert
(`DesignController` + `DesignPreferences` via `shared_preferences`, egal ob
Android oder Web). Die Auswahl überlebt Logout/Login und App-Neustart und
bleibt bestehen, bis sie explizit geändert wird. Default ist `Materia Pop`,
wenn nichts gespeichert ist. Geladen wird in `main.dart`
(`DesignPreferences.load()`), gespeichert automatisch bei jeder Änderung des
`DesignController`.

**Auswahl in den Einstellungen:** Unter *Einstellungen → Erscheinungsbild*
kann der Nutzer die Variante über den Katalog-`DesignSegmentedSwitch` wählen;
die Änderung wird sofort persistiert und wirkt auf den Showcase sowie künftig
auf migrierte Screens.

## Widget-Katalog (Struktur)

```
lib/design/
  design_variant.dart            # enum + Label/Tagline der 3 Designs
  theme/
    design_theme.dart            # DesignScope/DesignTheme (InheritedWidget)
    app_design.dart              # Resolver variant+brightness -> Tokens
  tokens/
    design_tokens.dart           # abstrakte Basisklasse (alle Werte variabel)
    materia_pop_tokens.dart      # Light + Dark
    aurora_glass_tokens.dart     # Light + Dark
    liquid_pulse_tokens.dart     # Light + Dark
  effects/
    grain_painter.dart           # GrainOverlay + Noise-Cache
  widgets/
    foundation/                  # Layer 0: DesignSurface, DesignText, DesignGlass
    primitives/                  # Layer 1: Button, Card, Chip, TextField,
                                 #           IconButton, Avatar, Badge, Divider,
                                 #           PressScale
    composite/                   # Layer 2: AppBar, BottomSheet, NavItem,
                                  #           SegmentedSwitch, ListTile,
                                  #           UserCard
    showcase/                    # Layer 3: ShowcaseSection, ColorSwatch,
                                 #           TokenSpec
```

## Token-Spezifikation (Beispiel Materia Pop, Light)

Alle Werte sind in `DesignTokens` als benannte Getter definiert und werden
pro Design/Modus neu belegt. Auszug:

- Farben: `background`, `surface`, `primary`, `secondary`, `accentA`,
  `accentB`, `textHigh`, `textLow`, `glow`, `success`, `warning`, `danger`
- Radien: `sm 14 · md 20 · lg 26 · xl 30 · pill 999` (px)
- Spacing: `xs 4 · sm 8 · md 12 · lg 16 · xl 24 · xxl 32` (px)
- Typografie: `display 30/w900 · title 22/w700 · subtitle 18/w700 ·
  body 15/w400 · label 13/w600` (Chivo)
- Effekte: `grainOpacity 0.04 · glassBlur 6 · glassOpacity 0.65 · glowBlur 26 · useGlass false`

Die Showcase-Screens rendern die aktuelle Palette (`DesignColorSwatch`) und
eine Mess-Tabelle (`DesignTokenSpec`) live für das gewählte Design.

## Zugriff in Widgets

```dart
final tokens = DesignTheme.of(context);          // aktive DesignTokens
final variant = DesignScope.variantOf(context);  // aktives Design
DesignScope.notifierOf(context).value = DesignVariant.auroraGlass; // umschalten
```

## Verknüpfung

Der Showcase ist über das Hauptmenü erreichbar (Sidebar + System-Sheet,
Eintrag **Design Showcase**, Icon `palette_rounded`) und unter der Route
`/design-showcase` eingehängt.

## Governance & Migrationsregeln

Ab der Migration der bestehenden Screens gilt zwingend:

1. **Ein einziger Katalog** – alle Widgets (grundlegend *und* spezialisiert)
   leben unter `lib/design/widgets/` und werden von Screens nur zusammengesetzt.
2. **Vererbung & Hierarchie** – jedes Widget basiert auf einem einheitlichen
   Grund-Widget des Katalogs (Foundation → Primitive → Composite). Komplexe
   Widgets werden komponentenartig aus grundlegenderen Katalog-Widgets gebaut.
3. **Keine lokalen Widgets** – keine ad-hoc Widget-Definitionen mehr in Screens;
   jede Spezialisierung bekommt ihren Platz im Katalog und wird hier dokumentiert.
4. **Dokumentation** – jedes neue/überführte Widget ist in dieser Datei und
   (bei abweichenden Specs) in `doc/migration_plan.md` erfasst.

### Spezialisierte Widgets & Feature-Adapter

Ein *spezialisiertes* Widget, das ein Feature-Modell (z.B. `UserBasePublic`)
kennt, darf nicht ins abhängigkeitsfreie `lib/design/`-Layer gezwungen werden.
Stattdessen gilt:

- Das eigentliche, modell-unabhängige Widget liegt als **Composite im Katalog**
  (z.B. `DesignUserCard` mit `imageUrl`/`name`/`subtitle`).
- Die Feature-Ebene stellt einen **dünnen Adapter** bereit, der das Modell auf
  die Katalog-Parameter abbildet (z.B. `UserCard` → `DesignUserCard`).
- Beide bauen ausschließlich auf Katalog-Primitives auf; keine lokalen
  Widget-Definitionen in Screens.

### Konsistenzregel: Eingabefelder

**Jedes Texteingabefeld** in einem migrierten Screen verwendet `DesignTextField`
aus dem Katalog. Es gibt keine ad-hoc `TextField`- mit `OutlineInputBorder`-
oder `InputDecoration`-Kombinationen mehr auf Screen-Ebene.

- Einfache Felder → `DesignTextField` mit den Katalog-Parametern.
- Felder mit einer Sichtbarkeitsauswahl (wie `VisibilityBadge`) → `suffix`-
  Parameter am `DesignTextField`.
- Zwei zusammengehörige Felder nebeneinander (z.B. Benutzername + Server) →
  zwei `Expanded(DesignTextField(...))` in einem `Row`.
- Nur wenn ein `TextField` technisch nicht durch `DesignTextField` abbildbar
  ist (z.B. ein read-only-Date-Picker-Trigger), darf ein token-gestylter
  `TextField` mit `Material(type: MaterialType.transparency)`-Wrapper
  verwendet werden – aber auch nur, bis ein entsprechendes Katalog-Widget
  (z.B. `DesignPickerField`) existiert.

Diese Regel stellt sicher, dass **jeder Input denselben Fokus-Glow, dieselbe
Border, dieselbe Hintergrundfarbe und dieselbe Schrift** aus den aktiven
Design-Tokens bekommt.

### Bereits migrierte Katalog-Widgets

- **`DesignAvatar`** (`primitives`) – Kreis-Avatar mit Bild oder Initialen.
  Unterstützt HTTP(S)-, `data:`- und rohe Base64-Bilder (via
  `resolveImageProvider`) und ist damit vollwertiger Ersatz für das alte
  `UserAvatar` (core). Baut auf `DesignText` + Token-Palette.
- **`DesignUserCard`** (`composite`) – Personenzeile, komponiert aus
  `DesignCard` + `DesignAvatar` + `DesignText` + `DesignBadge`. Modell-frei
  (`imageUrl`, `name`, `subtitle?`, `isSelf`, `onTap`); Feature-Screens
  mappen ihr Modell darüber (Adapter: `UserCard`).
- **`DesignCard`** / **`DesignCard.list`** (`primitives`) – Erhöhte
  Oberflächen-Karte (glas-first oder solid mit Shadow/Border).
  `DesignCard.list` rendert vertikal gestapelte Kinder mit konsistentem
  horizontalem Padding (`spaceLg`) und vertikalem Abstand (`spaceMd`).
  Schatten (`surfaceShadow`) wird **sowohl in Solid- als auch in Glas-Mode**
  angewendet, sodass alle Designs konsistente Tiefe vermitteln.
  **`margin`** umgibt die gesamte Karte (inkl. Dekoration/Shadow) mit
  externem Abstand; Standard ist `EdgeInsets.symmetric(horizontal:
  tokens.spaceLg)` für einheitlichen Seitenabstand aller Karten.
  `EdgeInsets.zero` entfernt den Abstand (z.B. wenn der Parent-Container
  den Abstand steuert, wie bei `ListView`-Padding oder Screen-Padding).
- **`DesignTextField`** (`primitives`) – Katalog-Textfeld (ersetzt Material
  `TextField`). Parameter: `hint`, `controller`, `obscure`, `keyboardType`,
  `textAlign`, `maxLength` (blendet den Zähler via `counterText: ''` aus),
  `prefixIcon`, `suffix` (Widget, z.B. VisibilityBadge). Baut auf
  Token-Palette + `radiusMd`; Fokus zeigt Primärfarbe und Glow-Schatten.
- **`DesignButton`** (`primitives`) – Katalog-Button mit den Varianten
  `filled` / `outlined` / `ghost` / `patterned` / `text`. `text` rendert einen
  reinen Text-Link (transparenter Hintergrund, Primärfarbe). `loading: true`
  blendet den Button aus und zeigt einen `CircularProgressIndicator` an Stelle
  des `icon` (kein lokaler Spinner nötig). `fullWidth` spannt den Button über
  die gesamte Breite.
- **`DesignAppBar`** (`composite`) – Nicht-Material AppBar aus `DesignText`
  (kein eigenes `DesignSurface`). Rendert einen transparenten 72 px-Strip mit
  `tokens.spaceXs` Boden-Padding; der parent Screen wickelt die gesamte Seite
  (AppBar + Body) in ein einziges `DesignSurface`, damit Gradient und Grain
  unterbrechungsfrei laufen. Status-bar-sicher (`SafeArea`).

Der fortschreitende Umstieg Screen für Screen ist in
[`doc/migration_plan.md`](doc/migration_plan.md) als abhakbare Liste
(Screens sortiert nach mobiler Menüposition, mit allen Widgets) hinterlegt.

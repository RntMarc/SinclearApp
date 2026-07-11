# Design System – Beyond "Aurora Glass"

Ein einheitliches, markengebundenes Design-System für die Beyond-App (Marke
Sinclear). Alle Screens beziehen ihre UI ausschließlich aus dem Widget-Katalog
unter `lib/design/` (Barrel-Import: `package:sinclear_beyond/design/beyond.dart`).
Keine direkten Material-Widgets, keine hartcodierten Farben in Screens.

## 1. Konzept

**Aurora Glass** kombiniert tiefe, ruhige Flächen mit Frost-Glas-Elementen,
einem dezenten Filmkorn und einem markanten Blau→Magenta-Verlauf als
wiedererkennbarer Signatur.

- **Marke:** Beyond by Sinclear. Signatur-Gradient `#0064EA → #BC0091`.
- **Modi:** Dark (Default) + Light, beide voll ausgestaltet.
- **Effekte:** Frost-Glas (Blur + Transparenz), Filmkörnung (selbst gebaut),
  Glow auf Interaktivem. Keine Fremdpakete für Effekte.

## 2. Prinzipien

- **Tokens zuerst.** Farben, Radien, Spacing, Glas- und Glow-Werte sind
  ausschließlich in `lib/design/tokens/beyond_tokens.dart` definiert. Screens
  greifen über `context.beyond` (bzw. `context.beyondColor`) darauf zu.
- **Katalog, nicht Screen-lokal.** Jedes wiederverwendbare Element liegt im
  Katalog und baut hierarchisch aufeinander auf
  (primitives → components → composite).
- **Kontrast.** Text ≥ 4.5:1 zum Hintergrund. Nie `Colors.white`/`Colors.black`
  direkt – über Tokens.
- **Einheitlichkeit.** Derselbe Button, dieselbe Card, dieselbe Nav überall.
- **Do:** Glass für Panels, Gradient für primäre Aktionen/Marken-Akzent,
  Glow für aktive Zustände.
- **Don't:** harte Schatten ohne Weichheit, Neon überall, generische
  Material-Standard-Cards, feste Farbwerte im Screen.

## 3. Token-Referenz

### Farben (`BeyondColors`)
| Token | Dark | Light | Einsatz |
|---|---|---|---|
| `surfaceBase` | `#011219` | `#F6F8FC` | App-Hintergrund |
| `surfaceRaised` | `#0B1B25` | `#FFFFFF` | gehobene Flächen |
| `surfaceGlassFill` | `#1FFFFFFF` | `#73FFFFFF` | Glas-Füllung |
| `surfaceGlassStroke` | `#33FFFFFF` | `#B3FFFFFF` | Glas-Rand |
| `onSurface` | `#E6E1E5` | `#0A1622` | Primärtext |
| `onSurfaceVariant` | `#AEB8C2` | `#5A6573` | Sekundärtext |
| `onSurfaceMuted` | `#7C8794` | `#8A93A0` | Tertiärtext |
| `borderSubtle` | `#1FFFFFFF` | `#1A0A1622` | Trenner |
| `brandBlue` | `#0064EA` | `#0064EA` | Markenakzent |
| `brandMagenta` | `#BC0091` | `#BC0091` | Markenakzent |
| `success`/`warning`/`danger`/`info` | siehe Tokens | semantisch | Status |
| `scrim` | `#CC011219` | `#990A1622` | Modal-Scrim |

Gradient: `BeyondBrand.signature` (135°, blue→magenta).

### Radien (`BeyondRadii.standard`)
`sm 8 · md 14 · lg 22 · xl 32 · pill 999` (px)

### Spacing (`BeyondSpacing.standard`, 4dp-Raster)
`xs 4 · sm 8 · md 12 · lg 16 · xl 24 · xxl 32 · xxxl 48` (px)

### Glas (`BeyondGlassTokens`)
| | blurSigma | fillOpacity | strokeOpacity |
|---|---|---|---|
| Dark | 18 | 0.12 | 0.20 |
| Light | 14 | 0.55 | 0.70 |

### Glow (`BeyondGlowTokens`)
- `brandBoxShadow`: `brandBlue @ α0.45`, blur 18 (aktive/interaktive Elemente)
- `softBoxShadow`: weicher Schatten, blur 24, offset (0,8)

### Motion (`BeyondMotion.standard`)
`fast 150ms · med 250ms · slow 400ms`, Kurven `easeOutCubic` / `easeOutExpo`.

### Typografie (`BeyondTypography`, Chivo)
| Style | Weight | Size | Style | Einsatz |
|---|---|---|---|---|
| `display` | w900 | 34 | italic | Hero |
| `titleLarge` | w900 | 22 | italic | Haupt-Seitentitel (AppBar) |
| `titleMedium` | w700 | 18 | normal | Abschnitts-/Sub-Titel |
| `headline` | w700 | 16 | normal | Content-Header |
| `bodyLarge` | w400 | 16 | – | Fließtext groß |
| `bodyMedium` | w400 | 14 | – | Fließtext Standard |
| `bodySmall` | w400 | 12 | – | Meta/Hinweis |
| `label` | w600 | 13 | – | Buttons/Labels |
| `labelSmall` | w600 | 11 | – | Chips, Kategorie-Überschriften |

## 4. Widget-Katalog (Spezifikation)

### Primitives
- **`BeyondSurface`** – Basis-Hintergrund. Füllt `surfaceBase`, malt dezenten
  Brand-Glow (oben rechts), optional globales Korn (im App-Root bereits global
  zugeschaltet → hier `grain:false`). Props: `child`, `grain`, `brandGlow`.
- **`BeyondGlass`** – Frost-Panel. **Echtes Blur ist opt-in (`blur:true`) und
  standardmäßig AUS** – die Glas-Optik kommt aus `surfaceGlassFill` +
  `surfaceGlassStroke` + `softBoxShadow`/`brandBoxShadow`. `brandedBorder` =
  1px Signatur-Gradient-Rand. `blur`/`blurSigma` nur sparsam für einzelne,
  kleine Vordergrund-Elemente (nie Listen/Sidebar/Bottom-Nav). Props: `child`,
  `padding`, `borderRadius`, `glow`, `brandedBorder`, `fill`, `blur`,
  `blurSigma`.
- **`BeyondGlow`** – Glow-Wrapper. `active` → Brand-Glow, sonst Soft-Shadow.
- **`BeyondGradientBackground`** – Signatur-Verlauf als Hintergrund.

### Components
- **`BeyondCard`** – erbt `BeyondGlass`, `padding` Standard 16, Radius `lg`.
- **`BeyondButton`** – Varianten `primary` (Gradient + Glow), `glass`,
  `ghost`. `height` 48, Radius `pill`, `label`/`icon`/`isLoading`/`fullWidth`.
- **`BeyondText`** (+ `BeyondDisplay/Title/Headline/Body/Label`) – `kind`
  wählt Typo-Stufe, `brandGradient` färbt Text mit Signatur-Verlauf.
- **`BeyondChip` / `BeyondBadge`** – Glas-Pill bzw. Status-Badge.
- **`BeyondDivider` / `BeyondAvatar`** – Trenner; Avatar mit Bild/Initialen,
  optional `ring` (Gradient-Kranz).
- **`BeyondAppBar`** – transparent, Titel via `BeyondTitle` (Gradient).
- **`BeyondScaffold`** – Scaffold mit `BeyondSurface`-Body, transparentem
  Hintergrund, `extendBodyBehindAppBar`.
- **`BeyondSheet`** – `BeyondSheet.show(context, child)` → Glas-Bottom-Sheet
  mit Drag-Handle, Radius `xl` oben.
- **`BeyondListTile` / `BeyondNavItem`** – Glas-Liste; `selected` →
  `brandBlue @ α0.16` + Glow.
- **`BeyondBottomNav`** – schwebende Glas-Nav, `destinations`
  (Icon+Label+active+onTap).
- **`BeyondSidebar`** – Glas-Sidebar (Desktop), `children` frei komponierbar;
  `BeyondSidebarBrand` zeigt Logo + Wortmarke.
- **`BeyondCategoryHeader`** – Kategorie-Label (`labelSmall`, `brandBlue`).
- **`BeyondBrandLogo`** – Logo + "Beyond" (Wortmarke mit Gradient).

### Composite
- **`BeyondSection`** – Titel + Inhalt, Horizontal-Padding `lg`.
- **`BeyondEmptyState`** – Icon (Gradient-Kreis) + Titel + Beschreibung + Aktion.
- **`BeyondLoader`** – Spinner in `brandBlue`.
- **`BeyondDialog`** – `BeyondDialog.show(...)` → Glas-Dialog mit Titel,
  Text, Confirm/Cancel (Glass-Buttons).

## 5. Navigation & AppBar (Bestand)
- Mobile: Kategorien (System, Gemeinschaft, Start, Unterwegs, Organisation) als
  `BeyondBottomNav`; Tap öffnet `BeyondSheet` mit Untereinträgen.
- Desktop: `BeyondSidebar` mit `BeyondSidebarBrand` + `BeyondCategoryHeader` +
  `BeyondNavItem`.
- Haupt-Seitentitel in `BeyondAppBar` (ALL CAPS, `titleLarge`), Sub-Seiten
  `titleMedium` in normal case.

## 6. Migration (Phase 2)
Screens ersetzen direkte `Card`/`Scaffold`/`AppBar`/`ListTile`/`Chip` sowie
hartcodierte `Color(...)`/`Colors.` durch Katalog-Äquivalente aus
`package:sinclear_beyond/design/beyond.dart`. Tokens kommen immer aus
`context.beyond`.

## 7. Effekte-Verteilung
- **Filmkorn:** liegt **nicht** global und **nicht** im Hintergrund. Es wird
  gezielt auf Elementen mit Verlauf-, Glas- oder Blur-Wirkung eingeblendet
  (`BeyondGrainTexture` über `BeyondGlass`, `BeyondButton` (primary),
  `BeyondGradientBackground`). Der Noise-Tile wird **einmal** in ein gecachtes
  `ui.Image` gerendert und pro Element mit einem einzigen `ImageShader`-Draw
  gekachelt – sehr günstig.
- **Brand-Glow:** pro `BeyondSurface` (jeder Screen) als dezenter
  Hintergrund-Verlauf.
- **Performance-Regel:** `BackdropFilter` (Blur) ist teuer, besonders unter
  Impeller und bei Layout-Änderungen (z. B. Fenstergröße). Daher Glas per
  Default transparent + Rand + Glow statt Echt-Blur. Echt-Blur nur gezielt
  einzeln einsetzen.

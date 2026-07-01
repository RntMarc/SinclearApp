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

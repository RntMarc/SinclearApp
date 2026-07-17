# Improvement Plan

Globale Code-Gesundheit, Performance, UI-Konsistenz und neue Funktionen.
Nach Abschluss der Migration von Material 3 → eigenes Design-System (siehe
gelöschte `migration_plan.md`) geht es jetzt um grundlegende Verbesserungen.

Status-Legende: `- [ ]` = offen · `- [x]` = erledigt · `- [~]` = in Arbeit / teilweise.

---

## A. Projekt-Gesundheit (Foundation)

### A1. Dart SDK & Flutter aktuell halten
- `pubspec.yaml`: `sdk: ^3.12.2`, Flutter `>=3.44.0` (laut lock)
- Prüfen ob neuere Stabile verfügbar ist → `flutter upgrade --check`
- Nach Upgrade: `dart fix --dry-run` + `dart fix --apply` für automatische Migrationen

### A2. Dependencies auf neuesten Stand bringen
- `flutter pub outdated` laufen lassen
- Für jedes Major-Upgrade Changelog prüfen (Breaking Changes)
- Besonders beobachten:
  - `go_router` (häufige API-Änderungen)
  - `flutter_map` + `latlong2` (Map-Integration)
  - `firebase_*` (Breaking Changes bei Firebase)

### A3. `analysis_options.yaml` verschärfen `[x]`
Vorschlag für aktivierte Regeln:
```yaml
linter:
  rules:
    - avoid_print
    - curly_braces_in_flow_control_structures
    - prefer_initializing_formals
    - prefer_final_fields
    - unnecessary_brace_in_string_interps
    - unnecessary_import
    - use_build_context_synchronously
```

- [x] `analysis_options.yaml` erweitert (7 Regeln)
- [x] `dart analyze` durchlaufen: 0 Issues (vorher 17 info)
- [x] `edit_social_screen.dart` (8 Stellen): fehlende `{}` bei `if` ergänzt
- [x] `user_models.dart` (6 Stellen): fehlende `{}` bei `if` ergänzt
- [x] `onboarding_screen.dart:217`: `mounted`-Check vor async gap ergänzt
- [x] `calendar_service.dart`: initializing formals verwendet (`this._api`, `this._auth`)
- `require_trailing_commas`, `prefer_const_*`, `always_declare_return_types` etc. bewusst weggelassen (zu viele bestehende Verstöße – später mit `dart fix` nachrüstbar)

### A4. Testabdeckung aufbauen
Aktuell: **1 Testdatei** (`test/design_showcase_test.dart`)

- [ ] Unit-Tests für Services (`api_client.dart`, `recipes_service.dart`, etc.)
- [ ] Widget-Tests für Katalog-Komponenten (`DesignButton`, `DesignCard`, etc.)
- [ ] Integrationstests für kritische User-Flows (Login → Forum → Post erstellen)

---

## B. Dead Code entfernen

### B1. Orphaned Widgets
- [x] `lib/features/recipes/widgets/recipe_card.dart` gelöscht (durch `DesignCard` ersetzt, nirgends importiert)
- [x] Leeres `widgets/`-Verzeichnis unter recipes entfernt

### B2. Veraltete Importe und Codepfade
- [x] `lib/core/theme/app_theme.dart` entfernt – Theme in `app.dart` inline via `ColorScheme.fromSeed`
- [x] `google_fonts`-Abhängigkeit aus `pubspec.yaml` entfernt (nur noch von `app_theme.dart` genutzt)
- [x] Leeres `lib/core/theme/`-Verzeichnis entfernt (inkl. leerem `noise/`-Unterordner)

### B3. Tote `null`-Checks (dart analyze Warnings)
- [x] `active_shares_screen.dart:54` – entfernt (parseApiDate gibt non-nullable DateTime zurück)
- [x] `session_map_screen.dart:235` – entfernt
- [x] `shared_locations_screen.dart:32` – entfernt

### B4. Unnötige Imports
- [x] `location_sender.dart:4` – `import 'package:flutter/material.dart'` durch `foundation.dart` ersetzt

---

## C. Performance

### C1. Große Dateien aufteilen (> 500 Zeilen)
| Datei | Zeilen | Aktion |
|---|---|---|
| `lib/features/explore/screens/detail_screen.dart` | 1199 | Tab-Composites in eigene Dateien auslagern |
| `lib/features/recipes/screens/recipe_detail_screen.dart` | 1027 | `_ReviewsSection` etc. in separates File |
| `lib/features/onboarding/screens/onboarding_screen.dart` | 764 | Pages einzeln, OnboardingService auslagern |
| `lib/features/shell/main_shell.dart` | 750 | Desktop/Mobile-Layouts trennen |
| `lib/features/feedback/screens/feedback_detail_screen.dart` | 715 | – |
| `lib/features/travel/screens/trip_detail_screen.dart` | 677 | Tab-Content in separate Widgets |
| `lib/features/forum/screens/post_detail_screen.dart` | 605 | – |
| `lib/features/user/models/user_models.dart` | 583 | Model-Klassen pro Feature aufteilen |
| `lib/features/notifications/services/notification_service.dart` | 573 | – |
| `lib/features/explore/screens/explore_screen.dart` | 555 | – |
| `lib/features/calendar/screens/calendar_screen.dart` | 542 | – |
| `lib/features/location_sharing/screens/integration_setup_screen.dart` | 531 | (wird in E1 migriert) |
| `lib/features/explore/screens/category_screen.dart` | 514 | – |
| `lib/features/forum/screens/forum_detail_screen.dart` | 505 | – |

- [ ] `detail_screen.dart` aufteilen (1199 Zeilen – höchste Priorität)
- [ ] `recipe_detail_screen.dart` aufteilen (Reviews in eigene Datei)
- [ ] `main_shell.dart` Desktop/Mobile-Logik trennen
- [ ] `onboarding_screen.dart` Pages auslagern
- [ ] Weitere große Dateien bei Gelegenheit aufteilen

### C2. `ListView` ohne `.builder()` ersetzen `[x]`
Erzeugt alle Kinder eager – bei langen Listen Performance-Problem.

- [x] `trip_detail_screen.dart:480` → `SingleChildScrollView` + `Column` (3 section children)
- [x] `settings_screen.dart:112` → `SingleChildScrollView` + `Column` (statische Seite)
- [x] `event_detail_screen.dart:257` → `SingleChildScrollView` + `Column` (statische Detailseite)
- [x] `forum_detail_screen.dart:367` → `SingleChildScrollView` + `Column`
- [x] `forum_list_screen.dart:101,112,174` → Loading/Error/Empty → `SingleChildScrollView` + `Column`
- [x] `post_detail_screen.dart:255,267,295` → Loading/Error/Main → `SingleChildScrollView` + `Column`

*location_sharing-Stellen entfallen (Feature entfernt).*

### C3. `Image.network` ohne Caching konsolidieren `[x]`
- [x] `recipe_list_screen.dart:117` → `CachedNetworkImage` + Import
- [x] `recipe_detail_screen.dart:600` → `CachedNetworkImage` + Import

### C4. `explore_map.dart` Marker-Memoization
- [ ] Markers werden bei jedem Build neu durch `places.map(...)` erzeugt – in `initState` oder via `ValueNotifier` cachen

### C5. State Management evaluieren
Aktuell: Jeder Screen nutzt rohes `setState` in `StatefulWidget`, was bei jedem Aufruf den gesamten Subtree rebuildet.

- [ ] Prüfen ob `ValueNotifier` / `ChangeNotifier` für Screen-lokalen State sinnvoll ist
- [ ] Evtl. `provider` für Feature-übergreifenden State (z.B. Benutzerdaten, Bookmark-Status)
- Siehe AGENTS.md: Built-in Lösungen bevorzugen, `provider` nur bei klarem Bedarf

### C6. `const`-Konstruktoren nachrüsten
- [ ] Sämtliche `StatelessWidget`-Klassen auf fehlende `const`-Konstruktoren prüfen und ergänzen
- [ ] `const` in `build()`-Methoden fördern (reduce rebuilds)

---

## D. UI-Konsistenz

### D1. `core/widgets/user_avatar.dart` (letzter Material-Nutzer außer location_sharing)
- [ ] Nutzt `Theme.of(context)` → auf `DesignTheme.of` umstellen oder komplett durch `DesignAvatar` ersetzen

### D2. `core/widgets/web_update_banner.dart` (web-only)
- [ ] `TextButton` → `DesignButton`(text)
- [ ] `FilledButton.tonal` → `DesignButton`(filled)
- [ ] `Theme.of(context)` → `DesignTheme.of(context)`

### D3. Bekannte Inkonsistenzen aus der Migration normalisieren
- [ ] `CommentInput`-Duplikat vereinheitlichen (`feedback` + `forum` → eine Definition im Katalog)
- [ ] `DesignTextField` um `maxLines`-Support erweitern (für `CommentInput`, `EventFormSheet`)
- [ ] `VisibilityBadge`: `PopupMenuButton` beibehalten oder Katalog um Dropdown ergänzen
- [ ] `ExploreSearchOverlay.slider`: `Slider` beibehalten oder Katalog um Slider-Komponente ergänzen

---

## E. location_sharing vorerst entfernen `[x]`

Da location_sharing momentan zu viele Probleme macht und unzuverlässig funktioniert, ist eine komplette Neuimplementation in der Zukunft besser, als ein halb-kaputtes System irgendwie aufrecht zu erhalten. Daher ist auch eine Anpassung an die neue UI unnötig und alle Funktionen zum Standort Teilen werden erst einmal aus dem Code der App entfernt.

**Erledigt:**
- [x] Alle 12 Dateien in `lib/features/location_sharing/` gelöscht
- [x] `lib/main.dart`: imports, Instanziierung, Constructor-Args entfernt
- [x] `lib/app.dart`: imports, Felder, Constructor-Args, AppScope-Args entfernt
- [x] `lib/router/router.dart`: imports, Route `/standort-teilen` + Subroutes entfernt, auth redirect bereinigt
- [x] `lib/core/di/app_scope.dart`: imports, Felder, Constructor-Args entfernt
- [x] `lib/features/shell/main_shell.dart`: `_standortWarningShown` + SnackBar entfernt, `_titleForLocation` bereinigt, `_categoryForLocation` bereinigt, mobile Kategorie-Sheet Eintrag entfernt, Desktop-Sidebar Eintrag entfernt; `_SheetItem.comingSoon` aufgeräumt
- [x] `lib/core/config/notification_config.dart`: `location_sharing.started` cases aus allen 3 Switch-Statements entfernt
- [x] `lib/features/notifications/widgets/notification_sheet.dart`: `location_sharing.started` Navigation entfernt

---

## F. Debugging & Logging

### F1. Zentrales Logging einführen
- [ ] `package:logging` zu `dependencies` hinzufügen
- [ ] Zentrale `Logger`-Instanz pro Feature/Service (z.B. `final log = Logger('api_client');`)
- [ ] `debugPrint`-Aufrufe in `lib/core/network/api_client.dart` durch `log.fine(...)` ersetzen
- [ ] `dart:developer`-Logs in `image_compressor.dart`, `image_provider_helper.dart`, `android_update_service.dart` auf `logging` umstellen (oder zumindest konsolidieren)

### F2. `BuildContext` über async gaps absichern
- [ ] `lib/features/onboarding/screens/onboarding_screen.dart:217` – `mounted`-Check vor `setState`/Navigation
- [ ] `lib/features/location_sharing/screens/active_shares_screen.dart:87` – `mounted`-Check
- [ ] Generell: Pattern `if (mounted) setState(...)` nach jedem `await` standardisieren
- [ ] Evtl. Hilfs-Mixin `MountedState` einführen:
  ```dart
  mixin MountedState<T extends StatefulWidget> on State<T> {
    void guardedSetState(VoidCallback fn) {
      if (mounted) setState(fn);
    }
  }
  ```

### F3. Globales Error-Handling
- [ ] `runZonedGuarded` in `main.dart` für nicht-catchte Fehler
- [ ] `FlutterError.onError` setzen (z.B. Logging + ggf. Remote-Logging)
- [ ] Error-Handling in Screens vereinheitlichen (try-catch pattern)

### F4. DevTools-Konfiguration
- [ ] `devtools_options.yaml` erweitern (logging_extensions, etc.)
- [ ] Prüfen ob Performance-Benchmarks via DevTools sinnvoll sind

---

## G. Neue Funktionen

*Hier können Ideen für neue Funktionen gesammelt werden – von Platzhaltern
bis zu komplett neuen Features. Format:*

### G1. Platzhalter umsetzen
| Screen | Status | Beschreibung |
|---|---|---|
| Admin | `[ ]` | Dashboard für Benutzer- und Inhalt-Moderation |
| Changelog | `[ ]` | Manuell vom Admin gepflegte Changelogs |
| Fotos | `[ ]` | Gemeinsame Foto-Galerie/Foto-Alben von Unsplash |
| Umfrage | `[ ]` | 1. Umfragen erstellen und abstimmen, 2. Gemeinsame Termine finden (ähnlich Doodle, FramaDate) |
| Abos | `[ ]` | Mitgliedschaften/Abos externer Dienste verwalten (z.B. Spotify, Netflix, Nintendo Familenabonnements unter Freunden) |

### G2. Bestehende Features erweitern
- `[ ]` Rezepte: Volltext-Suche, Favoriten-Filter, eigene Rezepte erstellen/bearbeiten
- `[ ]` Kalender: Wiederkehrende Events (Serien), Erinnerungen
- `[ ]` Travel: Checklisten-Packvorlagen, ÖPNV-Fahrten
- `[ ]` Entdecken: Offline-Karten, Filter nach Entfernung/Bewertung
- `[ ]` Forum: Push-Benachrichtigungen pro Thread, Mention-Auto-Vervollständigung
- `[ ]` Direktnachrichten / Chat-System

### G3. Querschnitts-Features
- `[ ]` **Offline-Modus**: Caching-Strategie für alle listenbasierten Screens
- `[ ]` **Dark/Light-Umschalter**: Fertigstellen und in den Einstellungen prominent platzieren
- `[ ]` **Benachrichtigungs-Einstellungen**: Pro Kategorie (neuer Post, neues Rezept, Event-Erinnerung)
- `[ ]` **Suche**: Globale Suche über alle Features
- `[ ]` **Onboarding**: Nach erstmaliger Einrichtung nicht mehr anzeigen (aktuell jedes Mal)
- `[ ]` **Barrierefreiheit**: Semantik-Labels, Screen-Reader-Support, dynamische Schriftgrößen testen
- `[ ]` **i18n**: Mehrsprachigkeit vorbereiten (mindestens Deutsch/Englisch)

---

## Reihenfolge / Abhängigkeiten

1. ✅ **(sofort)** **B** – Dead Code entfernen
2. ✅ **(sofort)** **A3** – analysis_options.yaml verschärfen
3. ✅ **(dringend)** **E** – location_sharing entfernen
4. ✅ **(dringend)** **F2** – `mounted`-Checks absichern (erledigt in A3)
5. ✅ **(parallel)** **C2** – ListView.builder-Fixes
6. ✅ **(parallel)** **C3** – Image.network → CachedNetworkImage
7. **(mittel)** **C1** – Große Dateien aufteilen (aufwändig, hoher Wert für Wartbarkeit)
8. **(mittel)** **D1-D3** – UI-Konsistenz (restliche Inkonsistenzen)
9. **(mittel)** **F1, F3, F4** – Logging + Error-Handling
10. **(mittel)** **C5, C6** – State Management + const (Performance)
11. **(später)** **A1, A2, A4** – SDK-Updates + Tests (kontinuierlich)
12. **(später)** **G** – Neue Funktionen (nach den Fundament-Verbesserungen)

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
| Datei | Zeilen | Aktion |
|---|---|---|---|
| ~~`lib/features/explore/screens/detail_screen.dart`~~ | ~~1199~~ | ✅ → 439 Z. (`detail_widgets.dart` +733 Z.) |
| ~~`lib/features/recipes/screens/recipe_detail_screen.dart`~~ | ~~1027~~ | ✅ → 361 Z. (`recipe_detail_widgets.dart` +664 Z.) |
| ~~`lib/features/onboarding/screens/onboarding_screen.dart`~~ | ~~764~~ | ✅ → 366 Z. (`onboarding_widgets.dart` +398 Z.) |
| ~~`lib/features/travel/screens/trip_detail_screen.dart`~~ | ~~679~~ | ✅ → 176 Z. (`trip_detail_widgets.dart` +496 Z.) |
| ~~`lib/features/shell/main_shell.dart`~~ | ~~707~~ | ✅ → 100 Z. (`shell_widgets.dart` +593 Z.) |
| ~~`lib/features/feedback/screens/feedback_detail_screen.dart`~~ | ~~715~~ | ✅ → 581 Z. (`feedback_detail_widgets.dart` +237 Z.) |
| ~~`lib/features/forum/screens/post_detail_screen.dart`~~ | ~~612~~ | ✅ → 466 Z. (`post_detail_widgets.dart` +219 Z.) |
| ~~`lib/features/user/models/user_models.dart`~~ | ~~597~~ | ✅ → Barrel + 3 Files |
| ~~`lib/features/notifications/services/notification_service.dart`~~ | ~~573~~ | ✅ → 421 Z. (`notification_display.dart` +159 Z.) |
| ~~`lib/features/explore/screens/explore_screen.dart`~~ | ~~555~~ | ✅ → 351 Z. (`explore_widgets.dart` +285 Z.) |
| ~~`lib/features/calendar/screens/calendar_screen.dart`~~ | ~~542~~ | ✅ → 454 Z. (`calendar_widgets.dart` +157 Z.) |
| ~~`lib/features/explore/screens/category_screen.dart`~~ | ~~514~~ | ✅ → 416 Z. (`category_widgets.dart` +88 Z.) |
| ~~`lib/features/forum/screens/forum_detail_screen.dart`~~ | ~~507~~ | ✅ → 395 Z. (`forum_detail_widgets.dart` +183 Z.) |

- [x] `detail_screen.dart` aufgeteilt (1199 → 439 Z.)
- [x] `recipe_detail_screen.dart` aufgeteilt (1029 → 361 Z.)
- [x] `onboarding_screen.dart` aufgeteilt (765 → 366 Z.)
- [x] `main_shell.dart` aufgeteilt (707 → 100 Z.)
- [x] `post_detail_screen.dart` aufgeteilt (612 → 466 Z.)
- [x] `user_models.dart` aufgeteilt (597 → Barrel + 3 Dateien)
- [x] `explore_screen.dart` aufgeteilt (555 → 351 Z.)
- [x] `calendar_screen.dart` aufgeteilt (542 → 454 Z.)
- [x] `category_screen.dart` aufgeteilt (514 → 416 Z.)
- [x] `forum_detail_screen.dart` aufgeteilt (507 → 395 Z.)
- [x] ~ `feedback_detail_screen.dart` (715 → 581 Z.) – Widgets extrahiert
- [x] ~ `notification_service.dart` (573 → 421 Z.) – Display-Logik in `notification_display.dart`

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

### C4. `explore_map.dart` Marker-Memoization `[x]`
- [x] `ExploreMap` in `StatefulWidget` umgewandelt, Marker in `_cachedMarkers` gecacht, nur bei `places`-Änderung neu berechnet

### C5. State Management evaluieren `[~]`

- [x] **Analyse**: 32 Screens mit `setState`-Muster, 2 ChangeNotifier (Auth, Notification), 2 ValueNotifier (Design, WebUpdate)
- [x] **A1 – ValueNotifier für UI-Toggles**: `_showMap` in `explore_screen.dart` + `category_screen.dart` auf `ValueNotifier` umgestellt → Full-Screen-Rebuild beim Kartenwechsel eliminiert
- [x] **A2 – RefreshIndicator**: Auf 14 Screens nachgerüstet (Travel, TripDetail, Calendar, EventDetail, Settings, Feedback, FeedbackDetail, RecipeList, RecipeDetail, RecipeCatalog, Contacts, UserDetail, Onboarding, SubscriptionDetail)
- [x] **Nachanalyse**: Paket B + C abgelehnt – Auth ändert sich nie bei sichtbarem Screen, Boilerplate-Einsparung marginal. Keine merkbare Verbesserung. C5 abgeschlossen ✅

### C6. `const`-Konstruktoren nachrüsten `[x]`
- [x] `prefer_const_constructors`, `prefer_const_literals_to_create_immutables` in `analysis_options.yaml` aktiviert
- [x] `dart fix --apply`: 56 const-Fixes in 26 Dateien
- [x] `dart analyze`: 0 Issues

---

## D. UI-Konsistenz

### D1. `core/widgets/user_avatar.dart` (letzter Material-Nutzer außer location_sharing)
- [x] Datei gelöscht (dead code, nirgends importiert)

### D2. `core/widgets/web_update_banner.dart` (web-only)
- [x] `TextButton` → `DesignButton`(text)
- [x] `FilledButton.tonal` → `DesignButton`(filled)
- [x] `Theme.of(context)` → `DesignTheme.of(context)`

### D3. Bekannte Inkonsistenzen aus der Migration normalisieren
- [x] `CommentInput`-Duplikat vereinheitlichen (`feedback` + `forum` → eine Definition im Katalog)
- [x] `DesignTextField` um `maxLines`-Support erweitern (für `CommentInput`, `EventFormSheet`)
- [x] `VisibilityBadge`: `PopupMenuButton` beibehalten – bereits Design-tokens-konform
- [x] `ExploreSearchOverlay.slider`: `Slider` beibehalten – bereits via `SliderTheme` eingefärbt

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

### G1. ÖPNV (Public Transport)

- [ ] Implementieren der neuen ÖPNV-Funktionen aus der API. Documentation prüfen und Umsetzung gemeinsam mit dem Nutzer planen. Es gibt Fahrten, die mit Reisen verknüpft sind und Fahrten, die eigenständig sind.

### G2. Abos (Subscriptions)

- [ ] Der API wurden neue Endpunkte hinzugefügt mit Funktionen zum Verwalten geteilter Abos unter Freunden. Es soll passend dazu ein neuer Screen Abos gebaut werden, auf dem der Nutzer alle Abonnements sieht, bei denen er ein Mitglied ist. Lies dir die Dokumentation der API dazu genau durch und befolge auch die Regeln zum Design exakt.

### G3. Erweiterung von Reisen und Events `[x]`

- [x] Event Detail Screen (`TravelEventDetailScreen`) – zeigt alle Event-Informationen (Name, Beschreibung, Datum/Zeit, Veranstalter, Adresse, Karte, Teilnehmer). Navigation von der Reise-Liste (Standalone) und aus dem Reise-Detail (Trip-Events).
- [x] Unterkunft Detail Screen (`AccommodationDetailScreen`) – zeigt Name, Beschreibung, Adresse, Telefon, Mail, Karte, zugeordnete Nutzer. Navigation durch Klick auf Unterkunftskarte im Reise-Detail.
- [x] Forum-Tab in der Reise-Detailansicht – wird dynamisch eingeblendet wenn `trip.forumId != null`. Zeigt `EmbeddedForumView` (identisch zum Forum-Detail-Screen, aber ohne Header/Title). API-Docs: "Alle Teilnehmer der Reise werden automatisch Mitglieder des Forums, verknüpfte Foren werden in der öffentlichen Foren-Liste ausgeblendet."
- [x] Zahlungen-Tab in der Reise-Detailansicht – wird dynamisch eingeblendet wenn verknüpfte Abos existieren (`subscriptionCount > 0`). API filtert automatisch nur die Abos, auf die der Nutzer Zugriff hat. Bei leerer Liste wird der Tab nicht angezeigt.
- [x] Neue Service-Methoden: `getEventUnified()`, `getAccommodationDetail()`, `getTripSubscriptions()`
- [x] Neue Modelle: `ForumBrief`-Klasse, `forumId`/`forum`/`subscriptionCount` in `TravelTrip`

### G4. Hinzufügen von Rezepten

- [ ] Neuer Screen zum Hinzufügen von Rezepten. Dort Formular mit allen Feldern, entsprechend Vorgaben der API. Bei Maßeinheiten nur Auswahl aus den erlaubten Einheiten der API. Wenn API nichts vorgibt, schlage eine Änderung vor mit allen gängigen Maßeinheiten in Rezepten (g, Esslöffel, Stück, Prise, ml, ...), aber ändere die API nicht selbst.

---

## Reihenfolge / Abhängigkeiten

1. ✅ **(sofort)** **B** – Dead Code entfernen
2. ✅ **(sofort)** **A3** – analysis_options.yaml verschärfen
3. ✅ **(dringend)** **E** – location_sharing entfernen
4. ✅ **(dringend)** **F2** – `mounted`-Checks absichern (erledigt in A3)
5. ✅ **(parallel)** **C2** – ListView.builder-Fixes
6. ✅ **(parallel)** **C3** – Image.network → CachedNetworkImage
7. ✅ **(mittel)** **C1** – Große Dateien aufteilen ✅
8. ✅ **(mittel)** **C4** – Marker-Memoization ✅
9. ✅ **(mittel)** **C6** – const-Konstruktoren nachrüsten ✅
10. ✅ **(mittel)** **D** – UI-Konsistenz ✅
11. **(mittel)** **F1, F3, F4** – Logging + Error-Handling
12. ✅ **(mittel)** **C5** – Paket A (ValueNotifier Toggles + RefreshIndicator) ✅
13. ✅ **(erledigt)** **G3** – Reisen/Events-Erweiterung ✅
14. **(später)** **A1, A2, A4** – SDK-Updates + Tests (kontinuierlich)
15. **(später)** **G1, G2, G4** – Weitere neue Funktionen

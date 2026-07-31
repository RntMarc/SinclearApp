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

## B. PT ausbauen

### B1. Mitfahrer verwalten

- [x] UI zum Hinzufügen/Entfernen von Mitfahrern in `PtJourneyDetailScreen` – Teilnehmerliste, Einladen via BottomSheet (User-Auswahl), Entfernen-Button für Ersteller

### B2. Abfahrtspläne

- [x] `PtDeparture`-Modell + `getStationDepartures()` in `pt_service.dart`
- [x] `PtDepartureBoardScreen` – Abfahrts-/Ankunftstafel mit Minuten-Auto-Refresh, umschaltbar
- [x] Station-Name-Tap in der Leg-Timeline öffnet Abfahrtsplan
- [x] Abfahrtsplan-Button in der `PtStationField`-Autocomplete-Liste

### B3. [API] Automatisches Aktualisieren von PT-Fahrten

- [ ] API hat `findStaleLegs()` vorbereitet, aber kein Cron-Job implementiert. Siehe Prompt unten.

#### Prompt für die API-Entwicklung

```
In der Sinclear API existiert die Methode `PtService::findStaleLegs()`, die alle
PtLeg-Einträge findet, deren `lastCheckedAt` älter als N Minuten ist (z. B. 5 min).
Diese Methode wird aktuell nirgends aufgerufen.

Bitte implementiere einen Cron-Job (z. B. via Cron/Task-Scheduler im Hosting),
der regelmäßig (alle 5 Minuten) `findStaleLegs()` aufruft und für jeden
stalen Leg die aktuellen Daten von Transitious `/api/v5/trip?tripId=...`
abruft und folgende Felder aktualisiert:

- `actualDeparture` / `actualArrival`
- `departureDelay` / `arrivalDelay`
- `departurePlatform` / `arrivalPlatform`
- `cancelled`
- `realTimeState`
- `lastCheckedAt`

Dabei müssen die Rate-Limits von Transitious beachtet werden:
nicht mehr als 5-10 Trip-Requests pro Batch und eine Pause zwischen
den Batches einplanen.

Nutze dazu den bestehenden `PtLegRepository` und `TransitiousClient`.
Die Logik für den API-Call pro Leg existiert bereits in `refreshLeg()`
in `PtService`.
```

### B4. Deep Linking

- [x] PT-Screens sind per GoRouter erreichbar; als `/reisen/pt/:id` registriert

---

## F. Debugging & Logging

### F1. Zentrales Logging einführen `[x]`
- [x] `package:logging` zu `dependencies` hinzugefügt
- [x] `lib/core/logging.dart` – `setupLogging()` mit Level-Filter (debug/release) + `debugPrint`-Ausgabe
- [x] `lib/main.dart` – `setupLogging()`-Aufruf beim Start, `developer.log` → `Logger('main')`
- [x] `api_client.dart` – `debugPrint` → `_log.fine()`, kDebugMode-Guards für String-Kosten behalten
- [x] `image_compressor.dart`, `image_provider_helper.dart` – `dart:developer` → gemeinsamer `Logger('image')`
- [x] `android_update_service.dart` – eigenes `_log`-Wrapper → `Logger('AndroidUpdateService')` mit passenden Levels (info/warning/severe)

### F2. `BuildContext` über async gaps absichern `[x]`
- [x] Alle 17 Verstöße in 10 Dateien gefixt (`flutter analyze` zeigt 0 `use_build_context_synchronously`)
- [x] `forum_detail_screen.dart` (3 Stellen): `_toggleJoin`, `_toggleNotifications`, `_votePost`
- [x] `travel_screen.dart` (2 Stellen): `_load()` – try + catch
- [x] `embedded_forum_view.dart` (1 Stelle): `_votePost`
- [x] `calendar/event_detail_screen.dart` (3 Stellen): `_edit`, `_addParticipant`, `_removeParticipant`
- [x] `settings/edit_profile_screen.dart` (2 Stellen): `_showImagePicker`, `_save` catch
- [x] `settings/edit_contact_screen.dart` (1 Stelle): `_save` catch
- [x] `settings/edit_social_screen.dart` (1 Stelle): `_save` catch
- [x] `settings/email_change_screen.dart` (2 Stellen): `_requestCode` catch, `_verifyCode` catch
- [x] `settings/discord_relink_screen.dart` (2 Stellen): `_startRelink` else-branch, `_verifyCode` catch
- [~] Evtl. Hilfs-Mixin `MountedState` einführen – bewusst weggelassen (zuwenig Cases für Abstraktion)

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

- [x] Implementieren der neuen ÖPNV-Funktionen aus der API. Documentation prüfen und Umsetzung gemeinsam mit dem Nutzer planen. Es gibt Fahrten, die mit Reisen verknüpft sind und Fahrten, die eigenständig sind.

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

### G5. Hinzufügen Statistiken-Screen (später, benötigt vorausgehende Arbeit an der API)

- [ ] Neuer Screen zur Ansicht der Statistiken unseres Discord-Servers.

### G6. Verbesserung Reisen

- [ ] Beim Anklicken der Karte auf dem Tab "Übersicht" auf dem Reise-Detail-Screen muss zum Tab "Karte" gewechselt werden. Es wurde schon mehrfach versucht, das zu implementieren, aber funktioniert noch nicht. Vielleicht liegt es daran, dass die Karte die Touches/Klicks erkennt und wir einfach ein unsichtbares UI-Element darüber legen sollten, damit die Karte wie ein Button funktioniert.
- [ ] Neuer Tab "ÖPNV" auf dem Reise-Detail-Screen. Dort Anzeige der verknüpften PT-Fahrten. Verknüpfung von Reisen via PT-Funktion bereits implementiert, nur Anzeige fehlt noch.

### G7. Verbesserung PT/ÖPNV

- [ ] Wenn eine PT-Fahrt mit einer Reise verknüpft wurde, sollte dort trotzdem keine extra Karte "An Reise angeheftet" erscheinen. Stattdessen Erweitern des Buttons oben, mit dem auch verknüpft werden kann, um klarer darzustellen, ob eine Fahrt gerade verknüpft ist oder nicht.
- [ ] Anzeige weiterer Details für jedes Leg. Aktuell steht nur Art des Transports, Startbahnhof, Abfahrtszeit, Zielbahnhof und Ankunftszeit dort. Es fehlen vor allem die Gleise.
- [ ] Verbesserung der Anzeige der Transportart. Aktuell stehen dort Werte wie "HIGHSPEED_RAIL", "WALK", "REGIONAL_RAIL", "SUBWAY", "SUBURBAN" oder "BUS". Es sollten aber gängige Begriffe wie "ICE/IC", "Laufen", "Regio", "U-Bahn", "S-Bahn" oder "Bus" dort stehen.
- [ ] Integration einer Karte, welche die Reiseroute in allen einzelnen Abschnitten abbildet. Die UI muss sinnvoll gestaltet werden.

### G8. Integration Teilen-Funktion + URI-Handler `[x]`

- [x] `share_plus` als Dependency hinzugefügt
- [x] `AppScope` um `appBaseUrl` erweitert (aus `API_BASE_URL` → `scheme://host` geparst)
- [x] `ShellShareButton` in der globalen AppBar (neben der Notification-Glocke) – teilt die aktuelle Seite via nativem Share-Dialog
- [x] Share-URL verwendet path-basiertes Format (`$baseUrl$path`), z. B. `https://sinclear.de/reisen`
- [x] Android Deep Link: Intent-Filter in `AndroidManifest.xml` für `https://sinclear.de`
- [x] Deep-Linking funktioniert jetzt plattformübergreifend (kein `#`-Fragment mehr)

---

## Reihenfolge / Abhängigkeiten

1. ✅ **(sofort)** **C** – Path-basiertes Routing ✅
2. ✅ **(nebenbei)** **B1, B2, B4** – PT ausbauen ✅ (B3 wartet auf API)
3. **(später)** **A1, A2, A4** – SDK-Updates + Tests (kontinuierlich)
4. **(später)** **B3** – [API] PT stale legs
5. **(später)** **F2, F3, F4** – Debugging & Error-Handling
6. **(später)** **G2, G4, G5, G6, G7** – Neue Funktionen

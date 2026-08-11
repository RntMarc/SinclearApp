# Benachrichtigungs-Fixes & Einstellungen – Umsetzungsplan

---

## 1. Bug: Routing zu `/forum/:id` schlägt fehl

### Ursache analysieren
- [ ] Route aus Notification-Payload ist `/forum/019fe126-...` (kein Präfix `/` fehlt, Format stimmt)
- [ ] `NotificationTypeLabel.route()` empfängt `data['route'] = '/forum/<uuid>'` und gibt ihn direkt zurück (kein Mapping nötig)
- [ ] `_handleNotificationTap` ruft `router.go(route)` auf – prüfen, ob `router` bereits initialisiert ist wenn Cold-Start vorliegt
- [ ] `ForumDetailScreen._load()` ruft `AppScope.of(context).forum.get(id)` → prüfen, ob Token beim App-Start noch nicht verfügbar ist
- [ ] In `ForumService.get()` prüfen, ob `_auth.getAccessToken()` beim Cold-Start einen Fehler wirft (Token noch nicht geladen)

### Fix: Token-Readiness beim Cold-Start sicherstellen
- [ ] In `_handleNotificationTap` (`main.dart`) Navigation mit kurzer `WidgetsBinding.instance.addPostFrameCallback`-Verzögerung oder nach `auth.init()` ausführen
- [ ] Alternativ: In `ForumDetailScreen._load()` vor dem API-Call explizit `await AppScope.of(context).auth.getAccessToken()` aufrufen und Token übergeben
- [ ] Sicherstellen, dass `auth.init()` in `_bootstrap()` vollständig abgeschlossen ist bevor `_handleNotificationTap` feuern kann

### Fix: Fehler-Logging verbessern
- [ ] In `ForumDetailScreen._load()` den `catch`-Block erweitern: `developer.log('Forum load error', error: e, stackTrace: st, name: 'forum_detail')`
- [ ] In `ForumService.get()` den Fehler mit HTTP-Statuscode loggen, um 401/403 vs. Netzwerkfehler zu unterscheiden

### Fix: Route-Auflösung absichern
- [ ] In `_handleNotificationTap`: Falls `route` auf `/forum/<id>` zeigt und kein Subrouten-Pfad enthalten ist, direkt `router.go('/forum/$id')` statt generischem `router.go(route ?? '/home')`
- [ ] Testen: Notification-Tap bei laufender App → funktioniert Routing?
- [ ] Testen: Notification-Tap bei Cold-Start (App war geschlossen) → funktioniert Routing?

---

## 2. Bug: Notification-Spam – Benachrichtigung kommt sofort erneut

### Ursache analysieren
- [ ] `_lastSeen` wird auf `items.first.createdAt` gesetzt – prüfen ob `toApiDate()` das exakt gleiche Format wie der API-Timestamp liefert (`2026-08-11 19:32:16.495`)
- [ ] API-Query nutzt `since=<timestamp>` – prüfen ob die API `>` (exklusiv) oder `>=` (inklusiv) filtert
- [ ] `startPolling` wird bei `AppLifecycleState.resumed` aufgerufen → beim Notification-Tap wird die App resumed und polling startet neu → `_lastSeen` ist evtl. noch nicht gesetzt
- [ ] `NotificationLifecycleObserver.didChangeAppLifecycleState` und `initState` von Screens triggern ggf. mehrfach `startPolling`

### Fix: `since`-Timestamp exklusiv machen
- [ ] In `NotificationService._poll()`: Wenn `_lastSeen` gesetzt ist, den Timestamp um 1 Millisekunde erhöhen, oder API-Parameter auf `after` (falls API das unterstützt) umstellen
- [ ] Alternativ: IDs der bereits gesehenen Notifications in einem `Set<String> _seenIds` cachen und doppelte Items vor dem Anzeigen filtern

### Fix: Lokale Deduplizierung einbauen
- [ ] `Set<String> _seenIds = {}` als Instanzvariable in `NotificationService` anlegen
- [ ] In `_poll()`: `items.where((item) => !_seenIds.contains(item.id)).toList()` filtern
- [ ] Gefilterte IDs zu `_seenIds` hinzufügen
- [ ] `_seenIds` bei `startPolling` / `stopPolling` **nicht** zurücksetzen (soll Session-weit erhalten bleiben)

### Fix: Mehrfaches `startPolling` verhindern
- [ ] In `NotificationService.startPolling()`: Guard einbauen – wenn `_pollingTimer != null && _lastSeen != null`, nicht neu starten sondern nur weiterlaufen lassen
- [ ] `NotificationLifecycleObserver`: `resumed`-Event nur reagieren wenn App tatsächlich vorher `paused` war (State-Flag `_waspaused` einführen)

### Fix: `markRead` nach Tap aufrufen
- [ ] In `_handleNotificationTap`: Nach erfolgreichem Routing `notification.markRead([id], token: token)` aufrufen
- [ ] Dafür Notification-ID aus dem Payload extrahieren und mitspeichern
- [ ] Sicherstellen dass `isRead: true` Notifications vom Server nicht mehr im `since`-Query zurückgegeben werden (API-Verhalten prüfen)

---

## 3. Feature: Benachrichtigungs-Methode in Einstellungen wählbar

### Modell & Persistenz
- [ ] `enum NotificationMethod { polling, unifiedPush, fcm }` anlegen in `lib/features/settings/models/notification_preference.dart`
- [ ] Hilfsmethode `NotificationMethod.availableFor(Platform)` anlegen:
  - Android: `[polling, unifiedPush]` (FCM später)
  - iOS: `[polling]` (UnifiedPush nicht verfügbar)
  - Web: `[polling]` (WebPush läuft separat, kein User-Toggle nötig)
  - Linux/Windows/macOS: `[polling]`
- [ ] `SharedPreferences`-Key `notification_method` zum Speichern/Laden nutzen
- [ ] Lade-Logik in `_bootstrap()` integrieren: `NotificationMethod.load()` vor `runApp`

### UI: Settings-Sektion
- [ ] In `settings_screen.dart` neue Sektion „Benachrichtigungen" unterhalb der bestehenden Push-Tile einfügen
- [ ] `DesignCard.list` mit `DesignListTile` pro verfügbarer Methode (Radio-Button-Stil)
- [ ] Nicht verfügbare Methoden ausblenden (nicht nur deaktivieren) via `kIsWeb`, `Platform.isAndroid` etc.
- [ ] FCM-Tile mit „Bald verfügbar"-Badge anzeigen und als disabled rendern (nur Android)
- [ ] Beim Wechsel der Methode: bisherigen Service stoppen → neuen starten

### Logik: Methoden-Wechsel umsetzen
- [ ] `_applyNotificationMethod(NotificationMethod method)` in `settings_screen.dart` implementieren:
  - `polling` gewählt: `unifiedPush.unregister()` → `notification.startPolling(token: token)`
  - `unifiedPush` gewählt: `notification.stopPolling()` → `_setupPush()` (bestehende Logik)
- [ ] Gewählte Methode in `SharedPreferences` persistieren
- [ ] In `_bootstrap()` / App-Start: gespeicherte Methode laden und entsprechenden Service starten

### UI: Bestehende „Push-Benachrichtigungen"-Tile anpassen
- [ ] Bestehende `_setupPush()`-Tile entfernen oder zu „UnifiedPush einrichten"-Detail-Link umbauen
- [ ] Aktive Methode als Subtitle der Sektion anzeigen (z. B. „Aktiv: Polling")
- [ ] UnifiedPush-Sektion nur auf Android zeigen (`!kIsWeb && Platform.isAndroid`)

### Router-Erweiterung (optional)
- [ ] Neue Route `/einstellungen/benachrichtigungen` in `router.dart` anlegen
- [ ] `NotificationSettingsScreen` als eigene Datei erstellen für Übersichtlichkeit
- [ ] Von `settings_screen.dart` per `context.push('/einstellungen/benachrichtigungen')` verlinken

---

## 4. Abschlussbericht (umgesetzt am 12.08.2026)

Alle Fixes und das Feature aus den Abschnitten 1–3 sind umgesetzt. Die
Sektionen 1–3 oben dienen als Checkliste; dieser Bericht beschreibt die
tatsächlich durchgeführten Änderungen.

### 1. Routing zu `/forum/:id` (Cold-Start)

**Ursache:** Der Tap-Handler wird in `_bootstrap()` **vor** `runApp`
registriert; `LocalNotificationHelper.init()` liefert bei einem Kaltstart das
Launch-Payload und feuert `_handleNotificationTap`, während die App noch gar
nicht läuft. `router.go()` lief damit in einen noch nicht gemounteten Router.

**Fixes (`lib/main.dart`):**
- `_navigate()`: Navigiert sofort, wenn der Router bereits am Widget-Tree hängt
  (`router.routerDelegate.navigatorKey.currentContext != null`); beim
  Cold-Start wird die Navigation per `addPostFrameCallback` in den ersten
  Frame verschoben, wenn Auth, Router und Token bereit sind.
- `_handleNotificationTap` bekommt jetzt `auth` und `notification` übergeben
  und ruft nach erfolgreicher Navigation `markRead([id])` auf (ID wird aus dem
  Payload extrahiert). Fehlerhafte Payloads und `markRead`-Fehler werden
  geloggt (`name: 'notification_tap'`).
- Die Route-Auflösung selbst war korrekt (`NotificationTypeLabel` mappt
  `/forum/<uuid>` unverändert durch); der eigentliche Bruch war der
  Navigations-Zeitpunkt.

**Logging (`lib/features/forum/services/forum_service.dart`, `forum_detail_screen.dart`):**
- `ForumService.get()` loggt Fehler mit Stacktrace und `name: 'forum_service'`;
  `ApiException` enthält dabei Statuscode + Error-Code (401/403 vs.
  Netzwerkfehler unterscheidbar).
- `ForumDetailScreen._load()` loggt jetzt mit `name: 'forum_detail'`.

### 2. Notification-Spam (sofort erneute Benachrichtigung)

**Ursache (in der API verifiziert, `SinclearAPI/src/Repository/NotificationRepository.php`):**
`GET /notifications` filtert mit `createdAt > since` (exklusiv), die
`createdAt`-Spalte hat Millisekunden-Präzision (`datetime(3)`). Der Client
sendete `since` aber ohne Millisekunden (`yyyy-MM-dd HH:mm:ss`) → eine
Notification im selben Sekundenintervall (`…16.495 > …16`) wurde bei jedem
Poll erneut geliefert und erneut angezeigt.

**Fixes (`lib/features/notifications/services/notification_service.dart`, `date_utils.dart`):**
- `toApiDate(..., withMilliseconds: true)` – `since` wird jetzt mit
  `.SSS`-Präzision gesendet, die Grenze ist damit echt exklusiv.
- Zusätzliche lokale Deduplizierung: `Set<String> _seenIds` (Session-weit,
  wird bei `startPolling`/`stopPolling` **nicht** zurückgesetzt) filtert
  doppelte Items vor dem Anzeigen/Stream-Emittieren. Defense-in-Depth gegen
  jede API-Grenzsemantik.
- `startPolling`-Guard: läuft bereits ein Timer mit gesetztem `_lastSeen`,
  wird nicht neu gestartet (verhindert Doppelstart durch Lifecycle-Event +
  Tap + Login).
- Poll-/markRead-Fehler loggen jetzt mit Stacktrace.

**Lifecycle (`notification_lifecycle_observer.dart`):**
- `_wasPaused`-Flag: Auf `resumed` wird nur reagiert, wenn die App
  tatsächlich pausiert war – ein Notification-Tap (der die App resumed)
  startet das Polling nicht unnötig neu.
- Der Observer pollt nur noch, wenn die aktive Zustell-Methode `polling` ist.

### 3. Benachrichtigungs-Methode in Einstellungen wählbar

**Neu (`lib/features/settings/models/notification_preference.dart`):**
- `enum NotificationMethod { polling, unifiedPush, fcm }` mit Label/
  Beschreibung und `NotificationMethodX.availableFor()`: Android → `polling`
  + `unifiedPush`, alle anderen Plattformen/Web → `polling` (FCM folgt).
- `NotificationPreference.load()/save()` über `SharedPreferences`-Key
  `notification_method`; `defaultMethod()`: Android → `unifiedPush` (bisheriges
  Verhalten), sonst `polling`.

**App-Start (`lib/main.dart`):**
- `_bootstrap()` lädt die gespeicherte Methode und startet den passenden
  Service direkt (kein Warten auf das erste Resume): `polling` →
  `notification.startPolling(...)`, `unifiedPush` → `unifiedPush.init(...)`.
  Fehler beim Token-Load sind abgefangen.
- `app.dart`/`app_scope.dart`: `ValueNotifier<NotificationMethod>` wird über
  die App gereicht (Settings ändern ihn, Lifecycle-Observer liest ihn).

**Settings (`settings_screen.dart`):**
- Die alte „Push-Benachrichtigungen"-Tile ist ersetzt durch die Sektion
  „Benachrichtigungen" mit Subtitle „Aktiv: \<Methode\>" und
  `DesignCard.list` + Radio-Tiles pro verfügbarer Methode (Busy-Spinner
  während des Wechsels).
- FCM-Tile nur auf Android, disabled, mit „Bald verfügbar"-Badge.
- `_applyNotificationMethod()`: Wechsel zu `polling` → UP-Deregistrierung +
  Start Polling; Wechsel zu `unifiedPush` → Polling stoppen + bestehender
  `_setupPush()`-Flow (Permission, Init, Distributor-Auswahl). Persistenz via
  `NotificationPreference.save()`.
- Logout deregistriert UP nur noch, wenn `unifiedPush` aktiv war (verhindert
  Plugin-Calls ohne Init).

**Login (`verify_screen.dart`):**
- Startet nur noch die gewählte Methode: Web → WebPush wie bisher; `polling` →
  `requestPermission()` + Polling; `unifiedPush` → Push-Setup. Kein doppeltes
  Polling + Push mehr.

### Tests & Verifikation

- `test/notification_service_test.dart`: +3 Tests – `since` behält
  Millisekunden-Präzision, bereits angezeigte Notifications werden nicht
  erneut emittiert, `startPolling` startet einen aktiven Poller nicht neu.
- `test/notification_lifecycle_test.dart`: um `getNotificationMethod` ergänzt.
- `flutter test`: 89 Tests grün. `flutter analyze`: keine Fehler.
- `flutter build web`: baut erfolgreich (dart2js deckte dabei zwei echte
  Fehler auf: `GoRouterDelegate.hasClients` existiert in go_router 17 nicht –
  ersetzt durch `navigatorKey.currentContext` – und ein `await` auf
  `void startPolling()`).

### Nicht umgesetzt (bewusst)

- Separate Route `/einstellungen/benachrichtigungen` + eigener Screen
  (Abschnitt 3, „optional"): Die Sektion liegt direkt in
  `settings_screen.dart` – kein zusätzlicher Screen nötig.
- `markRead` per Server-Seite „isRead wird beim `since`-Query nicht mehr
  geliefert": Die API liefert bereits nur `isRead = 0`; die
  Client-seitigen Fixes (exklusives `since` + Dedup) lösen den Spam vollständig.


# Sinclear Flutter App — Implementierungs-Checkliste

## Phase 1 — Datenmodell & Abhängigkeiten

- [ ] Paket `flutter_local_notifications` in `pubspec.yaml` eintragen und `flutter pub get` ausführen
- [ ] Paket `unifiedpush` in `pubspec.yaml` eintragen und `flutter pub get` ausführen
- [ ] Datei `lib/features/notifications/models/notification_item.dart` anlegen
  - [ ] Klasse `NotificationItem` mit Feldern: `id`, `type`, `title`, `body`, `data` (Map, nullable), `createdAt`
  - [ ] `factory NotificationItem.fromJson(Map<String, dynamic> json)` implementieren
  - [ ] `createdAt` wird aus ISO-8601-String geparst
- [ ] Test: `NotificationItem.fromJson()` mit Beispiel-JSON prüfen
  - [ ] Alle Felder werden korrekt belegt
  - [ ] `data: null` wird korrekt behandelt

## Phase 2 — NotificationService (Polling)

- [ ] Datei `lib/features/notifications/services/notification_service.dart` anlegen
- [ ] Klasse `NotificationService` mit Konstruktor, der `ApiClient` entgegennimmt
- [ ] Privates Feld `Timer? _pollingTimer`
- [ ] Privates Feld `String? _lastSeen` (ISO-8601-Timestamp des neuesten bekannten Items)
- [ ] `StreamController<List<NotificationItem>>` als broadcast anlegen
- [ ] Getter `Stream<List<NotificationItem>> get notifications` exponieren
- [ ] Methode `startPolling({required String token, Duration interval = const Duration(seconds: 60)})`
  - [ ] Stoppt vorherigen Timer falls aktiv
  - [ ] Startet neuen Timer mit übergebenem Intervall
  - [ ] Ruft `_poll()` sofort einmalig auf
- [ ] Methode `stopPolling()`
  - [ ] Cancelt Timer und setzt ihn auf null
- [ ] Private Methode `_poll(String token)`
  - [ ] Baut Query-Parameter `since` aus `_lastSeen` wenn vorhanden
  - [ ] Ruft `GET /notifications` (mit optionalem `?since=...`) über `ApiClient` auf
  - [ ] Deserialisiert Response zu `List<NotificationItem>`
  - [ ] Aktualisiert `_lastSeen` auf `createdAt` des neuesten Items
  - [ ] Fügt Items in den Stream ein, wenn Liste nicht leer
  - [ ] Fehler werden geloggt, werfen keine Exception (App darf nicht crashen)
- [ ] Methode `markRead(List<String> ids, {required String token})`
  - [ ] Sendet `POST /notifications/read` mit `{"ids": [...]}` über `ApiClient`
  - [ ] Leere Liste wird ohne Request abgefangen
- [ ] Methode `dispose()` ruft `stopPolling()` auf und schließt StreamController
- [ ] Service in vorhandener Dependency-Injection / Service-Locator-Struktur registrieren
- [ ] Tests
  - [ ] `startPolling()` triggert nach kurzer Zeit einen Poll
  - [ ] `_poll()` fügt Items korrekt in Stream ein (Mock-ApiClient)
  - [ ] `_poll()` mit leerem Response-Array fügt nichts in Stream ein
  - [ ] `_lastSeen` wird nach erstem Poll gesetzt
  - [ ] `stopPolling()` stoppt den Timer

## Phase 3 — Lifecycle-Integration

- [ ] `NotificationService.startPolling()` wird nach erfolgreichem Login aufgerufen
- [ ] `NotificationService.stopPolling()` wird bei Logout aufgerufen
- [ ] `WidgetsBindingObserver` in Root-Widget oder App-Level implementieren
  - [ ] Bei `AppLifecycleState.resumed`: Polling neu starten
  - [ ] Bei `AppLifecycleState.paused`: Polling stoppen
- [ ] Nur auf Android/native (nicht Web): Guard mit `!kIsWeb` oder Plattform-Check
- [ ] Manueller Test: App in Hintergrund bringen und zurückkommen, Polling startet neu

## Phase 4 — Lokale Systembenachrichtigungen (Android)

- [ ] Datei `lib/core/notifications/local_notification_helper.dart` anlegen
- [ ] Klasse `LocalNotificationHelper` mit statischen Methoden
- [ ] Statische Methode `init()`
  - [ ] `FlutterLocalNotificationsPlugin` initialisieren
  - [ ] Android-Channel `sinclear_main` mit `Importance.high` und `Priority.high` anlegen
  - [ ] In `main.dart` vor `runApp()` aufrufen (nur wenn `!kIsWeb`)
- [ ] Statische Methode `requestPermission()`
  - [ ] Notification-Permission anfragen (Android 13+)
  - [ ] Ergebnis zurückgeben (bool)
- [ ] Statische Methode `show(NotificationItem item)`
  - [ ] Zeigt Systembenachrichtigung mit `item.title` und `item.body`
  - [ ] Notification-ID aus `item.id.hashCode`
  - [ ] Tap-Handler: App öffnen und zu Route in `item.data['route']` navigieren wenn vorhanden
- [ ] `NotificationService._poll()` ruft `LocalNotificationHelper.show()` für jedes neue Item auf, wenn `!kIsWeb`
  - [ ] Maximal 3 Benachrichtigungen auf einmal anzeigen
- [ ] Manueller Test: App im Hintergrund, neues Item via API anlegen, Systembenachrichtigung erscheint

## Phase 5 — UnifiedPush Setup & Distributor-Auswahl

- [ ] Datei `lib/features/notifications/services/unified_push_service.dart` anlegen
- [ ] Klasse `UnifiedPushService` mit Konstruktor, der `ApiClient` und `String token` entgegennimmt
- [ ] Methode `checkAndSetup()`: Haupteinstiegspunkt für Setup-Flow
  - [ ] `UnifiedPush.getDistributors()` aufrufen
  - [ ] Falls Distributoren vorhanden: `_showDistributorPicker()` aufrufen
  - [ ] Falls keine Distributoren vorhanden: `_showNoDistributorScreen()` aufrufen
- [ ] Methode `_showDistributorPicker(List<String> distributors, BuildContext context)`
  - [ ] Dialog oder Bottom Sheet mit Liste der gefundenen Distributoren anzeigen
  - [ ] Nutzer wählt einen aus
  - [ ] `UnifiedPush.registerApp(distributor)` aufrufen
- [ ] Screen / Widget `NoDistributorScreen`
  - [ ] Informationstext: warum UnifiedPush besser ist als Polling alleine
  - [ ] Liste der empfohlenen Distributoren mit Name, kurzer Beschreibung und Quelle:
    - [ ] **ntfy** — F-Droid-Link und Play-Store-Link
    - [ ] **Gotify UP** — F-Droid-Link
    - [ ] **NextPush** — F-Droid-Link
  - [ ] Klick auf einen Distributor öffnet `url_launcher` mit dem jeweiligen Store-Link
  - [ ] Button „Ohne UnifiedPush fortfahren" → führt zu `PollingHintScreen`
- [ ] Screen / Widget `PollingHintScreen`
  - [ ] Erklärt dass Benachrichtigungen nur kommen wenn die App aktiv ist
  - [ ] Schritt-für-Schritt-Hinweise zur Akku-Optimierung, gegliedert nach Hersteller:
    - [ ] **Allgemein (Android):** Einstellungen → Apps → Sinclear → Akku → Keine Einschränkungen
    - [ ] **Samsung:** Gerätewartung → Akku → Hintergrundnutzung → Sinclear → Nicht eingeschränkt; Schlafmodus-Ausnahme prüfen
    - [ ] **Xiaomi/MIUI:** Autostart für Sinclear erlauben; Akku-Sparer auf „Keine Einschränkungen"; MIUI-Optimierung ggf. deaktivieren
    - [ ] **OnePlus/OxygenOS:** Akku-Optimierung für Sinclear deaktivieren; App-Sperre entfernen
  - [ ] Hinweis-Link zu dontkillmyapp.com
  - [ ] Button „Verstanden" → Setup abschließen, nur Polling
- [ ] Methode `register(String endpoint)` — Callback wenn Distributor Endpoint liefert
  - [ ] Sendet `POST /notifications/push-subscription` mit `{"type": "unifiedpush", "endpoint": "...", "keys": null}`
  - [ ] Speichert Endpoint lokal (SharedPreferences oder ähnlich) für Reconnect
- [ ] Methode `onMessage(String message)` — Callback für eingehende Push-Nachrichten
  - [ ] Parst `message` als JSON zu `NotificationItem`
  - [ ] Ruft `LocalNotificationHelper.show()` auf
- [ ] Methode `onUnregistered()` — Callback wenn Distributor Registrierung widerruft
  - [ ] Sendet `DELETE /notifications/push-subscription` mit gespeichertem Endpoint
  - [ ] Löscht gespeicherten Endpoint lokal
- [ ] Tests
  - [ ] `checkAndSetup()` ruft bei leerer Distributor-Liste `_showNoDistributorScreen()` auf (Mock)
  - [ ] `register()` sendet korrekte Payload an API (Mock-ApiClient)
  - [ ] `onMessage()` parst Nachricht korrekt und ruft LocalNotificationHelper auf (Mock)

## Phase 6 — Web Push Setup (nur Web/PWA)

- [ ] Datei `web/sw.js` anlegen (Service Worker)
  - [ ] `push`-Event-Handler: `event.data.json()` lesen, `showNotification()` aufrufen
  - [ ] `notificationclick`-Event-Handler: App-Tab fokussieren oder öffnen, Route aus `event.notification.data` navigieren
- [ ] Service Worker in `web/index.html` registrieren
- [ ] Datei `lib/features/notifications/services/web_push_service.dart` anlegen
- [ ] Klasse `WebPushService` (nur Kompilierung und Aufruf wenn `kIsWeb`)
- [ ] Methode `setup({required String token})`
  - [ ] Prüft ob Browser Web Push unterstützt
  - [ ] Fragt Notification-Permission an
  - [ ] Lädt VAPID Public Key von `GET /notifications/vapid-public-key`
  - [ ] Ruft `PushManager.subscribe()` mit VAPID Key auf
  - [ ] Extrahiert `endpoint`, `p256dh`, `auth` aus Subscription-Objekt
  - [ ] Sendet `POST /notifications/push-subscription` mit `{"type": "webpush", "endpoint": ..., "keys": {"p256dh": ..., "auth": ...}}`
- [ ] Methode `unsubscribe({required String token})`
  - [ ] Ruft `PushSubscription.unsubscribe()` auf
  - [ ] Sendet `DELETE /notifications/push-subscription`
- [ ] `WebPushService.setup()` wird nach Login aufgerufen, nur wenn `kIsWeb`
- [ ] Manueller Test im Browser: Permission erteilen, Subscription landet in DB, Push-Versand via API zeigt Browser-Notification

## Abschluss-Prüfung App

- [ ] Alle Unit-Tests grün
- [ ] Polling startet nach Login und stoppt bei Logout
- [ ] Polling startet nach App-Resume neu
- [ ] Auf Android: Systembenachrichtigung erscheint bei neuem Item (App im Vordergrund und Hintergrund getestet)
- [ ] UnifiedPush: Distributor-Auswahl funktioniert; Endpoint landet in API-DB
- [ ] UnifiedPush: Kein Distributor → Auswahlscreen erscheint → Store-Links öffnen sich
- [ ] UnifiedPush: Kein Distributor → „Ohne UP fortfahren" → Polling-Hinweisscreen erscheint
- [ ] Web Push: Browser-Notification erscheint wenn Tab inaktiv
- [ ] `markRead()` wird aufgerufen wenn Nutzer Benachrichtigungsliste öffnet
- [ ] Kein App-Crash bei API-Fehlern während des Pollings

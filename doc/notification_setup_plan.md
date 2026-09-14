# Plan: Striktes Benachrichtigungs-Setup auf Android

## Kontext & Ziele

Heute funktionieren Benachrichtigungen, aber das Setup ist zu lax: Der Nutzer
wählt in den Settings zwischen Polling/UnifiedPush, Fehlkonfigurationen
(UP ohne Distributor, Polling ohne Hintergrund-Lauf) werden nicht aktiv
verhindert, und es gibt keine Aufklärung (Vor-/Nachteile). Ziel ist ein
**verpflichtendes, gut informiertes Setup direkt nach dem Login** mit echten
Prüfungen und einem akkusparenden Hintergrund-Polling.

**Wichtig (API-Konflikt):** Die API-Doku verbietet FCM explizit. Daher bleibt
FCM als „Bald verfügbar" sichtbar (nicht wählbar), inkl. Info-Button.

## Festgehaltene Entscheidungen (aus Rückfragen)

| Thema | Entscheidung |
|---|---|
| FCM | Als „Bald verfügbar" anzeigen, nie aktivieren |
| Hintergrund-Polling | `flutter_foreground_task` (Foreground-Service, 5 Min) + `workmanager` (Fallback, 15 Min) |
| Polling-Intervall FG-Service | 5 Minuten |
| Wann fragen | Bei **jedem** Login (mandatory) |
| Platzierung | Eigener Screen nach `VerifyScreen`, vor Home/Onboarding |
| Überspringen | Nein, zwingend |

## Architektur-Überblick

- **Shared Selector** `NotificationMethodSelector` — identische Karte in Setup
  **und** Settings, mit Info-Button pro Option.
- **`NotificationMethodCoordinator`** — *eine* Stelle für Auswahl→Prüfung→Setup
  (heute dupliziert in `notification_settings_screen.dart` und
  `verify_screen.dart`).
- **Foreground-Service** (`flutter_foreground_task`) hält die App im
  Hintergrund am Leben; Polling läuft mit 5-Min-Intervall. Dismiss/Rechte-Entzug
  → Fallback.
- **`workmanager`** pollt als Fallback alle 15 Min, gesteuert über ein
  persistiertes `polling_foreground_active`-Flag.
- **Headless-Poller** (gemeinsamer Hintergrund-Poll für workmanager/optional
  FG-Task) mit persistiertem `last_seen`-Cursor zur Dedupe.

## Umsetzungsschritte

### A. Dependencies & native Konfiguration
- [x] `flutter pub add flutter_foreground_task` und `flutter pub add workmanager`
  (beide etabliert; erklären im PR: FG-Service + periodischer Fallback).
  → `flutter_foreground_task 11.0.3`, `workmanager 0.10.10`.
- [x] `android/app/src/main/AndroidManifest.xml`: `POST_NOTIFICATIONS`,
  `FOREGROUND_SERVICE`, `FOREGROUND_SERVICE_DATA_SYNC`
  (Android 14+ `foregroundServiceType="dataSync"`), `WAKE_LOCK` ergänzen;
  `<service android:name="com.pravera.flutter_foreground_task.service.ForegroundService" .../>`
  registrieren. (Exaktes Snippet gegen die gepinnte Plugin-Version prüfen —
  analog der aktuellen CalDAV-Service-Einträge.)
- [x] `minSdk` prüfen: `flutter_foreground_task` benötigt 21+, `workmanager` 14+
  (Flutter-Default 24 → i. O.).

### B. Persistenter Zustand
- [x] Neu `lib/features/notifications/services/polling_background_store.dart`:
  SharedPreferences-Keys `notification_last_seen` (API-Format, dedupe) und
  `polling_foreground_active` (bool, Koordination FG↔workmanager), plus
  read/write/reset. Zusätzlich `polling_foreground_heartbeat` (Stale-Heuristik).

### C. Foreground-Service (flutter_foreground_task)
- [x] Neu `lib/features/notifications/services/foreground_polling_service.dart`:
  `start()` (zeigt dauerhafte, leise Benachrichtigung, setzt
  `polling_foreground_active=true`), `stop()` (räumt Flag + Service + Fallback),
  `onNotificationDismissed`/`onDestroy` setzen das Flag zurück, damit der
  bereits registrierte WorkManager-Fallback übernimmt; `isActive`.
- [x] Batterie: Benachrichtigung `Importance.low`/`Priority.low`, kein Ton;
  Polling-Intervall 5 Min („lieber ein paar Minuten zu spät").
- [x] **Verifikation gegen Plugin-API:** ob die gepinnte Version das Main-Isolate
  am Leben hält (dann wird `NotificationService.startPolling(interval: 5min)`
  direkt wiederverwendet) **oder** Polling in `ForegroundTask.onRepeatEvent`
  läuft (dann headless Poller aus D). Entscheidung im Code dokumentieren.
  → Verifiziert an `flutter_foreground_task 11.0.3`: Der `TaskHandler` läuft in
  einem **eigenen Hintergrund-Isolate** (kein Main-Isolate-Keep-Alive). Daher
  pollt `onRepeatEvent` den headless Poller aus D.

### D. workmanager-Fallback + Headless-Poller
- [x] Neu `lib/features/notifications/services/background_poller.dart`:
  `@pragma('vm:entry-point') callbackDispatcher()` +
  `pollNotificationsHeadless()` — Refresh-Token laden → `/auth/refresh` →
  `GET /notifications?since=<last_seen>` → `flutter_local_notifications` anzeigen
  (API-`title`/`text` direkt; Fallback `NotificationTypeLabel`; **keine**
  Content-Enrichment, da Services nicht verfügbar) → `last_seen` vorschreiben.
- [x] Register/Cancel der periodischen Task (15 Min,
  `ExistingPeriodicWorkPolicy.KEEP`); Callback bricht ab, wenn
  `polling_foreground_active==true` (`foregroundAlive()` inkl. Heartbeat).
- [x] `ponytail:`-Kommentar: Token-Refresh ist hier minimal dupliziert (Upgrade:
  gemeinsamer Refresh-Helper mit `AuthService`); Duplikat-Risiko beim
  FG→workmanager-Übergang (in-memory vs. persistenter Cursor) als bekannte
  Obergrenze dokumentieren. Zusätzlich: gemeinsamer `last_seen`-Cursor + stabile
  Notification-IDs (FNV-1a) verhindern Doppelanzeigen.
- [x] Tap-Routing: Payload bleibt `NotificationItem.toJson` → bestehender
  Cold-Start-Tap-Handler (`main.dart`) löst Route auf.

### E. Shared Selector + Info-Buttons
- [x] Neu `lib/features/notifications/widgets/notification_method_selector.dart`:
  extrahiert die bestehende `DesignCard.list`/`DesignListTile`-Radio-Karte aus
  `notification_settings_screen.dart`; jede Zeile bekommt zusätzlich einen
  Info-`DesignIconButton` (`Icons.info_outline_rounded`) im `trailing`
  (Row aus Info-Icon + Radio/Spinner). FCM-Zeile (Android, „Bald verfügbar")
  ebenfalls mit Info-Button.
- [x] Neu `lib/features/notifications/widgets/notification_method_info_sheet.dart`:
  `showNotificationMethodInfoSheet(context, method)` via `showDesignSheet` —
  Funktionsweise + Vor-/Nachteile je Methode; bei UnifiedPush ein
  `DesignButton(variant: text)` „UnifiedPush Distributoren finden" →
  `launchUrl(Uri.parse('https://unifiedpush.org/users/distributors/'))`.
  Texte auf Deutsch, im Stil der bestehenden `PollingHintScreen`.
  Zusätzlich: Polling-Info verlinkt die bestehenden Geräte-Akku-Hinweise
  (`PollingHintScreen`).

### F. Setup-Koordinator (eine Stelle)
- [x] Neu `lib/features/notifications/services/notification_method_coordinator.dart`:
  `Future<NotificationMethodOutcome> apply(method)` mit schlankem Ergebnis-Typ
  (`applied` / `needsDistributor` / `noDistributor` / `permissionDenied`):
  - **Polling** → Berechtigung anfordern; verweigert → `permissionDenied`
    (nicht fortfahren); sonst FG-Service starten + `startPolling(5min)` →
    `applied`.
  - **UnifiedPush** → `unifiedPush.init` + Distributor-Prüfung; keiner →
    `noDistributor` (Auswahl wird **nicht** übernommen); mehrere →
    `needsDistributor` (Picker); einer/registriert → `applied`.
- [x] Refactor `notification_settings_screen.dart`
  (`_applyNotificationMethod`/`_setupPush`) und `verify_screen.dart`
  (`_setupPush`) auf den Koordinator — Duplikation entfernen.
  `UnifiedPushService` bietet dafür UI-freie Primitive
  (`registeredDistributor`/`availableDistributors`/`register`); Picker-Sheet
  liefert den gewählten Namen zurück.

### G. Setup-Screen & Routing
- [x] Neu `lib/features/notifications/screens/notification_setup_screen.dart`:
  Top-Level-Screen (ohne Shell, `DesignAppBar` wie `VerifyScreen`), nutzt
  `NotificationMethodSelector` + Koordinator; validiert bei Auswahl, blockiert
  `Weiter` bei `noDistributor`/`permissionDenied` mit Erklärung; speichert bei
  Erfolg `NotificationPreference` + setzt `AppScope.notificationMethod`;
  navigiert weiter zu `auth.onboardingCompleted ? '/home' : '/onboarding'`.
- [x] `lib/router/router.dart`: Route `/benachrichtigungen/einrichten`
  (Top-Level, parallel zu `/onboarding`) + Redirect-Ausnahmen: nicht nach
  `/onboarding` umleiten bei `!onboardingCompleted`; `!loggedIn` → `/`.
  Passender `pathPrefix` im Android-Manifest ergänzt (AGENTS.md).
- [x] `verify_screen.dart`: Nach `verifyCode` — Web behält den Web-Push-Pfad
  (`_setupWebPush`) und navigiert direkt; Android →
  `context.go('/benachrichtigungen/einrichten')`.

### H. Lifecycle, Bootstrap, Logout
- [x] `notification_lifecycle_observer.dart`: `stopPolling()` bei `paused`
  **nur**, wenn FG-Service nicht aktiv ist (sonst bleibt der 5-Min-Timer laufen).
- [x] `main.dart` Bootstrap: bei gespeicherter Polling-Methode FG-Service
  starten (prüft die Berechtigung ohne Dialog; dessen 5-Min-TaskHandler pollt
  im Hintergrund) und das In-App-`startPolling` (60 s) starten;
  `workmanager.initialize` + `foregroundPolling.initialize` (nur Android).
- [x] Logout-Pfad (`settings_screen.dart`): FG-Service stoppen, workmanager-Task
  canceln, `polling_foreground_active`/Cursor zurücksetzen (neben bestehendem
  `unifiedPush.unregister`).
- [x] `app_scope.dart`/`app.dart`: Koordinator + Foreground-Polling-Service in
  `AppScope` bereitstellen (Konstruktor-Injektion).
- [x] **Persistenter `notification_setup_completed`-Flag** (SharedPreferences):
  In `PollingBackgroundStore` als `notificationSetupCompleted`/`setNotificationSetupCompleted`.
  Nach erfolgreichem Setup (`_commit`) auf `true` setzen; beim Logout via
  `store.reset()` mit löschen. In `main.dart` Bootstrap: Flag prüfen;
  wenn Android + eingeloggt + `false` → `initialLocation` auf
  `/benachrichtigungen/einrichten` setzen. So sieht jeder Android-Nutzer
  nach einem Update (der zuvor kein Setup hatte) einmal den Setup-Screen,
  selbst ohne frischen Login. Router-Redirect für Deep-Links auf
  Nicht-Android-Plattformen bereits in Schritt G ergänzt.

### J. Setup-Screen: Auswahl + Weiter-FAB (statt Sofort-Setup)
- [x] Auswahl im `NotificationMethodSelector` markiert nur (`_select` →
  lokaler State); eingerichtet wird erst über den `DesignFab`
  (`Icons.arrow_forward_rounded`, unten rechts) via `_submit`.
- [x] Während des Setups zeigt der FAB `loading` (Spinner, Taps gesperrt);
  erst nach erfolgreichem `applied` wird `_commit` ausgeführt und der Screen
  verlassen.
- [x] Bei `permissionDenied`/`noDistributor`/Fehler bleibt der Screen offen,
  der FAB wechselt zurück zum Pfeil und es erscheint eine `_InfoBox`
  (Berechtigung → Hinweis auf die Smartphone-Einstellungen).
- [x] `DesignFab` erhält einen `loading`-Zustand (Spinner + gesperrte Taps),
  dokumentiert in `DESIGN.md`.
- [x] `NotificationMethodCoordinator` erzwingt die Benachrichtigungs-
  Berechtigung auch für UnifiedPush (injizierbar via `requestPermission`);
  die `requestPermission`-Prüfung ersetzt den bisher ignorierten Aufruf.

### I. Tests & Verifikation
- [x] Unit-Test `test/notification_method_coordinator_test.dart`: Polling ohne
  Berechtigung → `permissionDenied`; UP ohne Distributor → `noDistributor`;
  UP ohne Berechtigung → `permissionDenied`; erfolgreiche Pfade → `applied`.
- [x] Unit-Test `test/polling_background_store_test.dart`: Flag/Cursor
  read/write/reset.
- [x] Unit-Test `test/background_poller_test.dart`: `since`-Cursor-Advance +
  Dedupe (Fake `ApiClient`/`TokenStorage`).
- [x] Widget-Test `test/notification_method_selector_test.dart`: Rendering +
  Info-Button öffnet Sheet.
- [x] Widget-Test `test/notification_setup_screen_test.dart`: Auswahl richtet
  nicht sofort ein (erst der FAB); `permissionDenied` zeigt Infobox und bleibt
  offen; `noDistributor` zeigt Fehler und bleibt offen.
- [x] Widget-Test `test/design_fab_test.dart`: `DesignFab.loading` zeigt Spinner
  statt Icon und sperrt Taps.
- [x] `dart format`, `dart analyze` (bzw. `analyze_files`), `flutter test`.
  → `flutter analyze`: keine Issues; neue Tests grün; die gesamte Suite läuft
  bis auf einen **vorbestehenden**, unabhängigen Fehler in
  `test/guest_public_endpoints_test.dart` (auch auf unverändertem Stand rot).
  Zusätzlich `flutter build apk --debug` erfolgreich (Manifest/Plugins/Gradle).
- [ ] Manuell (Gerät): Login-Flow → Setup-Screen; Auswahl markiert nur,
  Weiter-FAB richtet ein (Spinner im FAB); lehnt der Nutzer die Berechtigung ab
  bzw. fehlt ein Distributor, bleibt der Screen offen und zeigt die Infobox;
  UP ohne Distributor wird abgelehnt; Polling zeigt FG-Benachrichtigung;
  Dismiss → workmanager-Fallback; Akku-Verhalten; **Update-Test**: Bestehendes
  APK (ohne Setup) updaten → Setup-Screen erscheint beim nächsten Start; Flag
  `notification_setup_completed` in SharedPreferences prüfen (true nach Setup,
  gelöscht nach Logout). **Kein** Auto-Deploy (deploy.py-Regel).
  → Erfordert ein physisches Gerät; durch den Admin zu prüfen (nicht vom Agent
  automatisiert ausgeführt, kein Auto-Deploy).

## Nicht-Teil des Umfangs
- Web Push / iOS / Linux bleiben unverändert (Setup-Screen gilt nur Android).
- Keine FCM-Integration; keine Änderung an `web/sw.js` oder Notification-Typen
  (kein neuer Typ).
- Auf Linux wird der Setup-Screen weder nach Login noch per Deep-Link angezeigt;
  `verify_screen.dart` überspringt ihn direkt, und der Router leitet
  `/benachrichtigungen/einrichten` auf Linux per Redirect zur Startseite weiter.

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
- [ ] `flutter pub add flutter_foreground_task` und `flutter pub add workmanager`
  (beide etabliert; erklären im PR: FG-Service + periodischer Fallback).
- [ ] `android/app/src/main/AndroidManifest.xml`: `POST_NOTIFICATIONS`,
  `FOREGROUND_SERVICE`, `FOREGROUND_SERVICE_DATA_SYNC`
  (Android 14+ `foregroundServiceType="dataSync"`), `WAKE_LOCK` ergänzen;
  `<service android:name="com.pravera.flutter_foreground_task.service.ForegroundService" .../>`
  registrieren. (Exaktes Snippet gegen die gepinnte Plugin-Version prüfen —
  analog der aktuellen CalDAV-Service-Einträge.)
- [ ] `minSdk` prüfen: `flutter_foreground_task` benötigt 21+, `workmanager` 14+
  (Flutter-Default 24 → i. O.).

### B. Persistenter Zustand
- [ ] Neu `lib/features/notifications/services/polling_background_store.dart`:
  SharedPreferences-Keys `notification_last_seen` (API-Format, dedupe) und
  `polling_foreground_active` (bool, Koordination FG↔workmanager), plus
  read/write/reset.

### C. Foreground-Service (flutter_foreground_task)
- [ ] Neu `lib/features/notifications/services/foreground_polling_service.dart`:
  `start()` (zeigt dauerhafte, leise Benachrichtigung, setzt
  `polling_foreground_active=true`), `stop()` (räumt Flag + Service),
  `onNotificationDismissed`-Callback → `stop()` + workmanager-Fallback
  aktivieren, `isActive`.
- [ ] Batterie: Benachrichtigung `Importance.low`/`Priority.low`, kein Ton;
  Polling-Intervall 5 Min („lieber ein paar Minuten zu spät").
- [ ] **Verifikation gegen Plugin-API:** ob die gepinnte Version das Main-Isolate
  am Leben hält (dann wird `NotificationService.startPolling(interval: 5min)`
  direkt wiederverwendet) **oder** Polling in `ForegroundTask.onRepeatEvent`
  läuft (dann headless Poller aus D). Entscheidung im Code dokumentieren.

### D. workmanager-Fallback + Headless-Poller
- [ ] Neu `lib/features/notifications/services/background_poller.dart`:
  `@pragma('vm:entry-point') callbackDispatcher()` +
  `pollNotificationsHeadless()` — Refresh-Token laden → `/auth/refresh` →
  `GET /notifications?since=<last_seen>` → `flutter_local_notifications` anzeigen
  (API-`title`/`text` direkt; Fallback `NotificationTypeLabel`; **keine**
  Content-Enrichment, da Services nicht verfügbar) → `last_seen` vorschreiben.
- [ ] Register/Cancel der periodischen Task (15 Min,
  `ExistingPeriodicWorkPolicy.KEEP`); Callback bricht ab, wenn
  `polling_foreground_active==true`.
- [ ] `ponytail:`-Kommentar: Token-Refresh ist hier minimal dupliziert (Upgrade:
  gemeinsamer Refresh-Helper mit `AuthService`); Duplikat-Risiko beim
  FG→workmanager-Übergang (in-memory vs. persistenter Cursor) als bekannte
  Obergrenze dokumentieren.
- [ ] Tap-Routing: Payload bleibt `NotificationItem.toJson` → bestehender
  Cold-Start-Tap-Handler (`main.dart`) löst Route auf.

### E. Shared Selector + Info-Buttons
- [ ] Neu `lib/features/notifications/widgets/notification_method_selector.dart`:
  extrahiert die bestehende `DesignCard.list`/`DesignListTile`-Radio-Karte aus
  `notification_settings_screen.dart`; jede Zeile bekommt zusätzlich einen
  Info-`DesignIconButton` (`Icons.info_outline_rounded`) im `trailing`
  (Row aus Info-Icon + Radio/Spinner). FCM-Zeile (Android, „Bald verfügbar")
  ebenfalls mit Info-Button.
- [ ] Neu `lib/features/notifications/widgets/notification_method_info_sheet.dart`:
  `showNotificationMethodInfoSheet(context, method)` via `showDesignSheet` —
  Funktionsweise + Vor-/Nachteile je Methode; bei UnifiedPush ein
  `DesignButton(variant: text)` „UnifiedPush Distributoren finden" →
  `launchUrl(Uri.parse('https://unifiedpush.org/users/distributors/'))`.
  Texte auf Deutsch, im Stil der bestehenden `PollingHintScreen`.

### F. Setup-Koordinator (eine Stelle)
- [ ] Neu `lib/features/notifications/services/notification_method_coordinator.dart`:
  `Future<NotificationMethodOutcome> apply(method)` mit schlankem Ergebnis-Typ
  (`applied` / `needsDistributor` / `noDistributor` / `permissionDenied`):
  - **Polling** → Berechtigung anfordern; verweigert → `permissionDenied`
    (nicht fortfahren); sonst FG-Service starten + `startPolling(5min)` →
    `applied`.
  - **UnifiedPush** → `unifiedPush.init` + Distributor-Prüfung; keiner →
    `noDistributor` (Auswahl wird **nicht** übernommen); mehrere →
    `needsDistributor` (Picker); einer/registriert → `applied`.
- [ ] Refactor `notification_settings_screen.dart`
  (`_applyNotificationMethod`/`_setupPush`) und `verify_screen.dart`
  (`_setupPush`) auf den Koordinator — Duplikation entfernen.

### G. Setup-Screen & Routing
- [ ] Neu `lib/features/notifications/screens/notification_setup_screen.dart`:
  Top-Level-Screen (ohne Shell, `DesignAppBar` wie `VerifyScreen`), nutzt
  `NotificationMethodSelector` + Koordinator; validiert bei Auswahl, blockiert
  `Weiter` bei `noDistributor`/`permissionDenied` mit Erklärung; speichert bei
  Erfolg `NotificationPreference` + setzt `AppScope.notificationMethod`;
  navigiert weiter zu `auth.onboardingCompleted ? '/home' : '/onboarding'`.
- [ ] `lib/router/router.dart`: Route `/benachrichtigungen/einrichten`
  (Top-Level, parallel zu `/onboarding`) + Redirect-Ausnahmen: nicht nach
  `/onboarding` umleiten bei `!onboardingCompleted`; `!loggedIn` → `/`.
- [ ] `verify_screen.dart`: Nach `verifyCode` — Web behält `_setupPush`
  (Web Push) und navigiert direkt; Android →
  `context.go('/benachrichtigungen/einrichten')`.

### H. Lifecycle, Bootstrap, Logout
- [ ] `notification_lifecycle_observer.dart`: `stopPolling()` bei `paused`
  **nur**, wenn FG-Service nicht aktiv ist (sonst bleibt der 5-Min-Timer laufen).
- [ ] `main.dart` Bootstrap: bei gespeicherter Polling-Methode FG-Service +
  `startPolling(5min)` starten (statt nur 60s `startPolling`);
  `workmanager.initialize` (nur Android).
- [ ] Logout-Pfad (`settings_screen.dart`): FG-Service stoppen, workmanager-Task
  canceln, `polling_foreground_active`/Cursor zurücksetzen (neben bestehendem
  `unifiedPush.unregister`).
- [ ] `app_scope.dart`/`app.dart`: Koordinator + Foreground-Polling-Service in
  `AppScope` bereitstellen (Konstruktor-Injektion).

### I. Tests & Verifikation
- [ ] Unit-Test `test/notification_method_coordinator_test.dart`: Polling ohne
  Berechtigung → `permissionDenied`; UP ohne Distributor → `noDistributor`;
  erfolgreiche Pfade → `applied`.
- [ ] Unit-Test `test/polling_background_store_test.dart`: Flag/Cursor
  read/write/reset.
- [ ] Unit-Test `test/background_poller_test.dart`: `since`-Cursor-Advance +
  Dedupe (Fake `ApiClient`/`TokenStorage`).
- [ ] Widget-Test `test/notification_method_selector_test.dart`: Rendering +
  Info-Button öffnet Sheet.
- [ ] `dart format`, `dart analyze` (bzw. `analyze_files`), `flutter test`.
- [ ] Manuell (Gerät): Login-Flow → Setup-Screen; UP ohne Distributor wird
  abgelehnt; Polling zeigt FG-Benachrichtigung; Dismiss → workmanager-Fallback;
  Akku-Verhalten. **Kein** Auto-Deploy (deploy.py-Regel).

## Nicht-Teil des Umfangs
- Web Push / iOS bleiben unverändert (Setup-Screen gilt nur Android).
- Keine FCM-Integration; keine Änderung an `web/sw.js` oder Notification-Typen
  (kein neuer Typ).

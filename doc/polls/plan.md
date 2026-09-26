# Plan: Umfragen (Polls) – vollständige Client-Integration

## Kontext & Ziele

Die Sinclear API stellt unter `/api/v2/polls` ein neues Modul für Umfragen
bereit, das drei innerlich stark unterschiedliche Arten unter einem gemeinsamen
`type`-Diskriminator bündelt:

| `type` | Vorbild | Kern |
|---|---|---|
| `form` | Google/Microsoft Forms | Beliebig viele Fragen (13 Fragetypen), Nutzer geben Antworten ein. |
| `appointment` | Doodle/Framadate | Terminvorschläge, Verfügbarkeit `yes`/`maybe`/`no`, optionale Gegenvorschläge, einmalige (änderbare) Abstimmung pro Nutzer/Option. |
| `vote` | anonymes Voting | Nur die Teilnahme wird erfasst (Doppelwahl verhindern), Stimmen werden gezählt; keine Verknüpfung Nutzer ↔ Antwort; einmalig, nicht änderbar. |

Ziel ist eine **komplette** Client-Integration: Liste, Detail, Erstellen und
Bearbeiten aller drei Typen, Teilnahme, Ergebnisse, Einladungen sowie die vier
Poll-Notification-Typen inkl. Deep Links und Ungelesen-Indikatoren.

## Festgehaltene Entscheidungen (aus Rückfragen)

| Thema | Entscheidung |
|---|---|
| Umfang | Komplett End-to-End: Liste, Detail, Erstellen/Bearbeiten aller 3 Typen, Teilnahme, Ergebnisse, Einladungen, Schließen/Finalisieren/Löschen. |
| Formular-Editor | Alle 13 Fragetypen der API, inkl. typspezifischer `config` (min/max, `allowOther`, `labels`, …). |
| Benachrichtigungen | Alle vier Typen vollständig (Deep Links, Ungelesen-Punkte, `sw.js`, Präferenzen `pollIds`). |
| Route / Label | `/umfragen`, Menü-Label „Umfragen“ (Icon `Icons.poll_rounded`). |
| Zusätzliche Oberflächen | Nur Ungelesen-Puls am Organisation-Menüeintrag; **kein** Home-Dashboard-Widget. |

## API-Vertrag (Quelle der Wahrheit)

Vor der Umsetzung wird der Vertrag nochmals gegen `openapi.yaml` bzw. den
SinclearAPI-MCP (`get_documentation`, Topics `polls`, `polls/types`,
`notifications/types`) verifiziert (AGENTS API-Compatibility). Der Vertrag
darf nicht aus dem Gedächtnis oder „wie früher“ übernommen werden.

### Endpunkte (alle JWT, Präfix `/api/v2/polls`)

| Zweck | Methode/Pfad | Service-Methode |
|---|---|---|
| Liste (Filter `type`,`status`, `page`,`limit`) | `GET /polls` | `list()` |
| Anlegen | `POST /polls` | `create()` |
| Detail (+`questions`/`options`/`participantStatus`) | `GET /polls/{id}` | `get()` |
| Meta/Settings | `PATCH /polls/{id}` | `update()` |
| Löschen | `DELETE /polls/{id}` | `delete()` |
| Schließen | `POST /polls/{id}/close` | `close()` |
| Einladungen | `GET/POST /polls/{id}/invites`, `DELETE …/{userId}` | `listInvites()`/`addInvites()`/`removeInvite()` |
| Formularantworten (roh) | `GET /polls/{id}/responses` | `listResponses()` |
| Formular absenden | `POST /polls/{id}/responses` | `submitResponse()` |
| Eigene Antwort | `GET /polls/{id}/responses/me` | `myResponse()` |
| Antwort ändern | `PATCH /polls/{id}/responses/{responseId}` | `updateResponse()` |
| Gegenvorschlag | `POST /polls/{id}/options` | `addCounterProposal()` |
| Gegenvorschlag löschen | `DELETE /polls/{id}/options/{optionId}` | `deleteOption()` |
| Verfügbarkeiten | `GET/PUT /polls/{id}/availability` | `listAvailability()`/`setAvailability()` |
| Finalisieren | `POST /polls/{id}/finalize` | `finalize()` |
| Abstimmungsstatus | `GET /polls/{id}/vote-status` | `voteStatus()` |
| Abstimmen | `POST /polls/{id}/vote` | `vote()` |
| Abstimmungsergebnis | `GET /polls/{id}/results` | `results()` |

### Schemas & Enums

DTOs (exakt aus `openapi.yaml`): `Poll`, `PollDetail`, `PollQuestion`,
`PollOption`, `PollInvite`, `PollResponse`, `PollAvailabilityVote`,
`PollResultEntry`, `PollVoteStatus`, `PollParticipantStatus`. Requests:
`PollCreateRequest`, `PollQuestionInput`, `PollOptionInput`,
`PollUpdateRequest`, `PollAnswerInput`, `PollResponseSubmitRequest`,
`PollAvailabilitySetRequest`, `PollCounterProposalRequest`,
`PollFinalizeRequest`, `PollVoteRequest`.

Enums: `type` (`form`/`appointment`/`vote`) · `status` (`open`/`closed`) ·
`accessMode` (`invited`/`all_users`) · `submissionMode` (`single`/`multiple`) ·
`resultsVisibility` (`creator`/`participants`) · `availability`
(`yes`/`maybe`/`no`). Fragetypen: `text`, `textarea`, `number`, `email`,
`coordinates`, `date`, `datetime`, `url`, `phone`, `single_choice`,
`multiple_choice`, `boolean`, `rating`.

Fehlercodes → deutsche Meldungen: `forbidden`, `not_found`, `poll_closed`,
`already_voted`, `already_responded`, `results_hidden`,
`counter_proposals_disabled`, `invalid_answer`, `invalid_config`,
`invalid_option`, `time_forbidden`/`date_forbidden`.

### Date/Time-Konvention (AGENTS)

- `closesAt` RFC 3339; `PollOption` getaktet `startAt`/`endAt` + `timezone`,
  ganztägig `startDate`/`endDate` (zivile Tage). `allDay` ist die einzige
  Wahrheit, welche Feldgruppe gilt.
- Ausschließlich `parseApiInstant`/`toApiInstant`,
  `wallTimeToInstant`/`instantToWallTime`, `formatInstantRangeInZone`,
  `displayDay` verwenden — **kein** manuelles UTC-Rechnen.

---

## Umsetzungsschritte (Reihenfolge)

### Phase 1: Datenschicht

- [ ] 1.1 `lib/features/polls/models/poll_models.dart` anlegen: Enums + DTOs
  mit handgeschriebenem `fromJson`/`toJson` (Projekt-Konvention — kein
  `json_serializable`/`build_runner`). Antwortwert-Semantik exakt nach
  `polls/types`: `boolean` „1"/„0", `coordinates` „lat,lon",
  `multiple_choice` JSON-Array, `date`/`datetime` Strings, `number`/`rating`
  Zahl. Listen-Wrapper mit `meta` (`total`, Pagination).
- [ ] 1.2 Date/Time-Felder über `date_utils` parsen/serialisieren
  (`parseApiInstant`/`toApiInstant`, `startDate`/`endDate` als `toApiDateOnly`).
- [ ] 1.3 `lib/features/polls/services/polls_service.dart` anlegen: schlanke
  Wrapper über `ApiClient` + `AuthService` (ein privater `_token()`), eine
  Methode pro Endpunkt, Fehler als `ApiException` durchreichen.
- [ ] 1.4 DI verdrahten: Feld `polls` in `lib/core/di/app_scope.dart`
  (Deklaration + Konstruktor + `of`); Instanz `PollsService(api: api,
  auth: auth)` in `lib/main.dart` und an `AppScope` übergeben.

### Phase 2: Router, Shell & Deep Links

- [ ] 2.1 `lib/router/router.dart`: `GoRoute /umfragen` mit Subrouten
  `/umfragen` (Liste), `/umfragen/neu` (Wizard), `/umfragen/:id` (Detail,
  dispatcht nach `type`), `/umfragen/:id/bearbeiten`,
  `/umfragen/:id/ergebnisse`, `/umfragen/:id/einladungen`.
- [ ] 2.2 `/umfragen` in die `isAuth`-Prüfung des `redirect` aufnehmen.
- [ ] 2.3 `lib/features/shell/widgets/shell_widgets.dart`:
  - `shellTitleForLocation`: `'/umfragen' → 'UMFRAGEN'`.
  - `shellCategoryForLocation`: `/umfragen` → `ShellNavCategory.organisation`.
  - Sheet-Item `('Umfragen', Icons.poll_rounded, '/umfragen')` statt `null`.
  - Desktop-Sidebar-Tile „Umfragen“ unter ORGANISATION ergänzen.
- [ ] 2.4 Ungelesen-Puls am Organisation-Eintrag (Bottom-Nav-Icon analog
  Gemeinschaft + Sidebar-Tile) mit `DesignPulseDot` — Quell-Getter aus
  Phase 3.3 (`hasUnreadPollContent`).
- [ ] 2.5 `android/app/src/main/AndroidManifest.xml`: `<data …
  pathPrefix="/umfragen" />` ergänzen (AGENTS-Pflicht). `DeepLinkHandler`
  bleibt unverändert (generisches Path-Mapping).

### Phase 3: Benachrichtigungen (alle vier Typen)

- [ ] 3.1 `lib/core/config/notification_config.dart`:
  - `route`: `poll_invite`/`poll_counter_proposal`/`poll_finalized`/
    `poll_deadline_reminder` → `/umfragen/{poll}` (Relation `poll`).
  - `title`, `fallbackBody`, `icon` (`Icons.poll_rounded`, Reminder
    `Icons.alarm_rounded`) für alle vier.
  - `category` → `'Umfragen'`; `customDataKey` → `'pollIds'`.
- [ ] 3.2 `lib/features/notifications/services/notification_content_resolver.dart`:
  Enrichment-Zweige `poll_*` — Umfrage-Titel via `PollsService.get()`, bei
  `poll_counter_proposal`/`poll_finalized` zusätzlich `proposer`/
  `finalized_option`; Fallback über `NotificationTypeLabel`.
- [ ] 3.3 `lib/features/notifications/services/notification_service.dart`:
  Unread-Getter `hasUnreadPollContent`, `unreadPollIds`,
  `unreadIdsForPoll(pollId)` (Relation `poll`).
- [ ] 3.4 `web/sw.js`: vier Einträge in `CONTENT_BY_TYPE` + `resolveRoute`
  für `poll`-Relation → `/umfragen/{id}`.
- [ ] 3.5 Lesen-Markierung: beim Öffnen von `PollDetailScreen`
  `notification.markRead(notification.unreadIdsForPoll(id), token: …)`;
  `refreshUnread()` beim Öffnen des Umfragen-Screens/Menüs (nicht bei jedem
  Poll).
- [ ] 3.6 Präferenzen: keine weitere Logik nötig — `pollIds` wird über
  `NotificationTypeLabel.customDataKey` automatisch unterstützt (verifizieren).

### Phase 4: Design-Katalog (Governance: keine lokalen Widgets)

- [ ] 4.1 Neu `lib/design/widgets/composite/design_poll_card.dart`: model-freier
  Listeneintrag (`DesignCard`) mit Typ-Label/Icon, Titel, Ersteller, Frist,
  Status, `pulseColor`, `onTap`.
- [ ] 4.2 Neu `lib/design/widgets/composite/design_question_field.dart`: rendert
  **einen der 13 Fragetypen** aus model-freiem `DesignQuestionSpec`
  (Typ-Enum, `config`, Optionen, Pflicht) mit `value`/`onChanged`; baut auf
  `DesignTextField`, `DesignChip`/`DesignSegmentedSwitch`, `DesignSlider`,
  `DesignPickerField`.
- [ ] 4.3 Neu `lib/design/widgets/composite/design_question_editor.dart`:
  Autoren-Pendant (Titel, Pflicht, `config` je Typ, Optionsliste
  hinzufügen/entfernen, `allowOther`).
- [ ] 4.4 Neu `lib/design/widgets/composite/design_availability_matrix.dart`:
  Doodle-Matrix (Optionen × Teilnehmer, `yes`/`maybe`/`no`) aus
  `DesignChip`/`DesignIconButton`.
- [ ] 4.5 Neu `lib/design/widgets/composite/design_poll_result_bar.dart`:
  Ergebnisbalken (auf `DesignCard`/`DesignSlider`-Optik).
- [ ] 4.6 Feature-Adapter (dünn, modellbewusst) unter
  `lib/features/polls/widgets/`: `PollCard` (→ `DesignPollCard`),
  `QuestionField` (→ `DesignQuestionField`), analog „UserCard →
  DesignUserCard“.
- [ ] 4.7 `DESIGN.md` um die neuen Katalog-Widgets ergänzen; `doc/polls/`
  (dieses Dokument) mit abweichenden Specs nachziehen.

### Phase 5: Screens

- [ ] 5.1 `lib/features/polls/screens/poll_list_screen.dart`: `GET /polls`,
  Filter (Typ/Status via `DesignSegmentedSwitch`), paginierter
  `ListView.builder` mit `PollCard`, Puls aus Unread-Registry, `DesignFab`
  → `/umfragen/neu`.
- [ ] 5.2 `lib/features/polls/screens/poll_create_screen.dart`: mehrstufiger
  Wizard — Typwahl (`DesignSegmentedSwitch`) → Basisdaten (`DesignTextField`,
  Frist inkl. Zeitzone, `accessMode`, typspezifische Optionen) → bei `form`
  Fragen-Editor (alle 13 Typen) → Einladungen (User-Suche,
  `inviteUserIds`); `POST /polls`.
- [ ] 5.3 `lib/features/polls/screens/poll_detail_screen.dart`: dispatcht per
  `type`; Kopf (Beschreibung Plain Text, Frist/Status, Ersteller) + Aktionen
  (Bearbeiten `PATCH`, Schließen, Löschen mit Bestätigungs-Sheet,
  `👑`-Logik nur wenn Admin-only). Teilnahme je Typ:
  - **form:** Fragen + eigener Status; „Antworten"/„Antwort bearbeiten“
    (`single`, offen); Ersteller/`participants`: Antworten + Ergebnisse.
  - **appointment:** `DesignAvailabilityMatrix` (Aliase, `PUT` ersetzt
    vollständig); Gegenvorschlag-Button (`allowCounterProposals`); Ersteller:
    „Termin festlegen“ (`finalize` → schließt).
  - **vote:** Optionen zur einmaligen Wahl (`optionIds[]`), nach `hasVoted`
    gesperrt; Ergebnisse erst nach `closed` (Ersteller).
- [ ] 5.4 `lib/features/polls/screens/poll_response_screen.dart`: Formular-
  Antwort-Formular (`DesignQuestionField` pro Frage), validiert Pflichtfelder
  lokal, `POST /responses` (bzw. `PATCH` bei Bearbeitung).
- [ ] 5.5 `lib/features/polls/screens/poll_invites_screen.dart`: Ersteller/
  Admin — `GET/POST/DELETE /invites`.
- [ ] 5.6 `lib/features/polls/screens/poll_results_screen.dart`: Formular-
  Antworten (`GET /responses`, Sichtbarkeit beachten) bzw. `GET /results`
  (nach `closed`).

### Phase 6: Tests & Doku

- [ ] 6.1 `test/polls_models_test.dart`: Enum-/DTO-Parsing inkl.
  Antwortwert-Semantik und Date/Time-Roundtrip
  (`toApiInstant`/`parseApiInstant`).
- [ ] 6.2 `test/notification_config_test.dart` erweitern: Poll-Routen,
  Titel/Body/Icon, `pollIds`-Denylist.
- [ ] 6.3 `test/notification_service_test.dart` erweitern: `unreadPollIds`,
  `unreadIdsForPoll`.
- [ ] 6.4 `test/notification_content_resolver_test.dart` erweitern:
  `poll_*`-Enrichment (Titel, Proposer, finalisierte Option, Fallback).
- [ ] 6.5 `doc/migration_plan.md` (bzw. DESIGN-Doku) um die neuen Screens
  ergänzen.

### Phase 7: Verifikation

- [ ] 7.1 `dart format` (Formatierung), `dart_fix` (Quick-Fixes),
  `analyze_files` (Linter, 0 Fehler).
- [ ] 7.2 `flutter test test/polls_models_test.dart
  test/notification_config_test.dart test/notification_service_test.dart
  test/notification_content_resolver_test.dart` grün.
- [ ] 7.3 Manuell (UI): Wizard aller drei Typen, Teilnahme, Ergebnis-
  Sichtbarkeit, Notification-Tap → `/umfragen/{id}`, Deep Link
  `/umfragen/...`, Ungelesen-Puls am Organisation-Eintrag.
- [ ] 7.4 Kein Auto-Deploy (AGENTS: Admin prüft manuell).

---

## Risiken & Hinweise

- Der Formular-Wizard mit 13 Fragetypen ist der größte Brocken.
  `DesignQuestionField` bündelt die Eingabe-Logik zentral, damit Anzeige
  (Teilnahme) und Editor (Autoren) dieselbe Spezifikation nutzen.
- `vote`-Anonymität: der Client erhält/zeigt nie `participantHash`; nur
  `hasVoted`/`votedOptionIds`.
- `PUT /availability` ist Full-Replace → die UI sammelt den kompletten
  Zustand und sendet ihn einmalig.
- `GET /polls/{id}/results` ist erst nach `closed` und nur für
  Ersteller/Admin sichtbar (`results_hidden` sonst) — im UI spiegeln.

---

## Umsetzungsnotizen (Abweichungen zur Planung)

Alle Phasen sind umgesetzt. Abweichungen von den oben genannten Details:

- **Filter statt `DesignSegmentedSwitch`:** Der vorhandene
  `DesignSegmentedSwitch` ist fest auf die Design-Auswahl verdrahtet und
  nicht generisch. Typ-/Status-/Modus-Filter nutzen daher
  `DesignChip`-Zeilen (Katalog-Widget) — gleiches Muster wie bestehende
  Screens.
- **Datum/Uhrzeit-Eingabe:** Der Katalog hat kein eigenes Date-Picker-Widget.
  `DesignQuestionField` enthält deshalb einen privaten Datum/Uhrzeit-Trigger
  im `DesignTextField`-Look (erlaubte Ausnahme laut DESIGN.md, bis ein
  Katalog-Widget existiert).
- **Antwortformular:** `PollResponseScreen` ist nicht deep-linkbar und wird
  per `Navigator.push` geöffnet (`/umfragen/:id/bearbeiten` bleibt der
  Meta-Edit). Die im Plan gelisteten Subrouten `/ergebnisse` und
  `/einladungen` sind vorhanden.
- **Gegenvorschlag:** Der Sheet-Wizard nutzt den wiederverwendbaren
  `AppointmentOptionEditor` (identisch zum Erstell-Wizard) statt einer
  eigenen Datumslogik.
- **Antwortwert-Semantik:** UI-Werte werden im Client zwischen Feature- und
  Design-Layer konvertiert (`PollAnswerInput.value`); `boolean` → `"1"/"0"`,
  `datetime` via `wallTimeToInstant`/`toApiInstant` in der effektiven Zone.
- **Antwort-Ergebnisse:** Formular-Rohantworten werden auf Label-Ebene
  gerendert (Auswahloptionen zu Labels aufgelöst); `vote`-Ergebnisse über
  `DesignPollResultBar`.


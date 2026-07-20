# Plan: ÖPNV-Integration (Public Transport)

## Übersicht

Integration der SinclearAPI-Public-Transport-Endpunkte in die Flutter-App.
Nutzer können ÖPNV-Verbindungen suchen, speichern (merken), auf der
TravelScreen-Timeline sehen und an Reisen (Trips) anheften.

---

## 1. API-Endpunkte (Übersicht)

| Methode | Pfad | Verwendung |
|---------|------|------------|
| `GET` | `/public-transport/stations?q=...` | Stationssuche (Autocomplete) |
| `GET` | `/public-transport/journeys?from=...&to=...` | Verbindungssuche |
| `POST` | `/public-transport/journeys` | Verbindung speichern |
| `GET` | `/public-transport/journeys/list` | Eigene Verbindungen abrufen |
| `GET` | `/public-transport/journeys/{id}` | Verbindungsdetails |
| `DELETE` | `/public-transport/journeys/{id}` | Verbindung löschen |
| `POST` | `/public-transport/journeys/{id}/refresh` | Echtzeitdaten aktualisieren |
| `POST` | `/public-transport/journeys/{id}/participants` | Teilnehmer hinzufügen |
| `DELETE` | `/public-transport/journeys/{id}/participants/{userId}` | Teilnehmer entfernen |

---

## 2. API-Lücke: PATCH-Endpunkt fehlt

**Problem:** Die API erlaubt kein nachträgliches Ändern einer gespeicherten
Fahrt. Insbesondere kann `tripId` (Verknüpfung mit einer Reise) nur beim
erstmaligen Speichern (`POST`) gesetzt werden.

**Benötigt:** `PATCH /public-transport/journeys/{id}`

Request-Body (alle Felder optional):

```json
{
  "tripId": "uuid" | null
}
```

- `tripId: "uuid"` → Fahrt an Reise anheften
- `tripId: null` → Fahrt von Reise lösen

**Status-Codes:** `200` (aktualisiertes PtSavedJourney), `404` (nicht
gefunden), `403` (nur Ersteller darf ändern).

**Action:**
- [ ] `PATCH /public-transport/journeys/{id}` in der API ergänzen
  (Request-Body: `tripId` nullable uuid)

---

## 3. Dateien (neu & angepasst)

- [x] `lib/features/travel/models/pt_models.dart` — NEU
- [x] `lib/features/travel/services/pt_service.dart` — NEU
- [x] `lib/features/travel/screens/pt_search_screen.dart` — NEU
- [x] `lib/features/travel/screens/pt_search_results_screen.dart` — NEU
- [x] `lib/features/travel/screens/pt_journey_detail_screen.dart` — NEU
- [x] `lib/features/travel/widgets/pt_station_field.dart` — NEU
- [x] `lib/features/travel/widgets/pt_journey_card.dart` — NEU
- [x] `lib/features/travel/screens/travel_screen.dart` — ANGEPASST
- [x] `lib/core/di/app_scope.dart` — ANGEPASST
- [x] `lib/main.dart` — ANGEPASST
- [x] `lib/app.dart` — ANGEPASST

---

## 4. Modelle (`pt_models.dart`)

Alle mit `factory fromJson()` nach bestehendem Muster (kein Code-Generation).

- [x] **PtStation** — `id`, `name`, `latitude`, `longitude`
- [x] **PtLeg** — `mode`, `lineName`, `lineProduct`, `fromStationId`,
      `fromStationName`, `toStationId`, `toStationName`, `tripId`,
      `plannedDeparture`, `plannedArrival`, `departureDelay`, `arrivalDelay`,
      `departurePlatform`, `arrivalPlatform`, `cancelled`, `realTimeState`
- [x] **PtJourneySearchResult** — `duration`, `transfers`, `departureTime`,
      `arrivalTime`, `legs`
- [x] **PtJourneySearchResponse** — `data` (List<PtJourneySearchResult>)
- [x] **PtSavedJourney** — `id`, `tripId`, `creatorId`, `fromStationId`,
      `fromStationName`, `toStationId`, `toStationName`, `departureTime`,
      `arrivalTime`, `duration`, `transfers`, `chosenAt`, `createdAt`, `legs`,
      `participants`
- [x] **PtSavedJourneyListResponse** — `data`, `meta`
- [x] **UserBrief** — `id`, `displayName`, `image`
- [x] **PtSaveJourneyRequest** — Hilfsklasse mit allen Feldern für POST

---

## 5. Service (`pt_service.dart`)

Neue Klasse `PublicTransportService`, analog zu `TravelService` aufgebaut:

- [x] `searchStations(query, {limit})` — `GET /public-transport/stations?q=...`
- [x] `findJourneys({from, to, departure, arriveBy, results, maxTransfers, pageCursor})`
      — `GET /public-transport/journeys?from=...&to=...`
- [x] `saveJourney(PtSaveJourneyRequest)` — `POST /public-transport/journeys`
- [x] `listJourneys({tripId, page, limit})` — `GET /public-transport/journeys/list`
- [x] `getJourney(id)` — `GET /public-transport/journeys/{id}`
- [x] `deleteJourney(id)` — `DELETE /public-transport/journeys/{id}`
- [x] `refreshJourney(id)` — `POST /public-transport/journeys/{id}/refresh`
- [x] `addParticipant(journeyId, userId)` — `POST .../participants`
- [x] `removeParticipant(journeyId, userId)` — `DELETE .../participants/{userId}`

### PtSaveJourneyRequest (Hilfsklasse)

```dart
class PtSaveJourneyRequest {
  String? tripId;
  String fromStationId;
  String fromStationName;
  String toStationId;
  String toStationName;
  String departureTime;
  String arrivalTime;
  int duration;
  int transfers;
  List<Map<String, dynamic>> legs;
  List<String> participantIds;
}
```

---

## 6. Screens

### 6a. `pt_search_screen.dart` — Suchmaske

- [x] Suchmaske erstellen (Von-Station, Nach-Station, Abfahrtszeit,
      Abfahrt/Ankunft-Umschalter, erweiterte Optionen einklappbar)
- [x] Suchen-Button → navigiert zu `PtSearchResultsScreen`

### 6b. `pt_search_results_screen.dart` — Suchergebnisse

- [x] Ergebnisliste aus `PtJourneySearchResult`-Cards
- [x] Tippen auf Card → Bottom-Sheet mit Leg-Details + Speichern-Button
- [x] Speichern-Dialog mit optionaler Reise-Auswahl (`POST .../journeys`)
- [x] Nach Speichern: Pop zurück zum TravelScreen mit Refresh

### 6c. `pt_journey_detail_screen.dart` — Detail einer gemerkten Fahrt

- [x] Header (Von → Nach, Zeiten, Dauer, Umstiege)
- [x] Leg-Timeline (vertikale Stepper-Ansicht)
- [x] Echtzeit-Refresh-Button (`POST .../refresh`)
- [x] An Reise anheften/lösen (`PATCH .../journeys/{id}`) — Platzhalter
- [x] Löschen-Button mit Bestätigung (`DELETE .../journeys/{id}`)

### 6d. `travel_screen.dart` — Anpassungen

- [x] FAB (`directions_bus_rounded`) → navigiert zu `PtSearchScreen`
- [x] PT-Sektion "ÖPNV-Fahrten" in die Timeline einfügen
- [x] PT-Journeys in `_load()` parallel laden (`GET .../journeys/list`)
- [x] PT-Journey-Card tappbar → navigiert zu `PtJourneyDetailScreen`

---

## 7. Widgets

- [x] **`pt_station_field.dart`** — TextFormField mit debounced Autocomplete
      via `GET /public-transport/stations?q=...`
- [x] **`pt_journey_card.dart`** — Wiederverwendbare Card für Timeline und
      Suchergebnisse (Icon, Von→Nach, Zeiten, Dauer)

---

## 8. Änderungen an bestehenden Dateien

- [x] **`lib/core/di/app_scope.dart`** — Feld `publicTransport` +
      `PublicTransportService`-Import ergänzen
- [x] **`lib/main.dart`** — `PublicTransportService` instanziieren und an
      `SinclearApp` übergeben
- [x] **`lib/app.dart`** — Parameter `publicTransport` aufnehmen und an
      `AppScope` weiterreichen

---

## 9. Routing

Keine neuen GoRouter-Routen nötig. Die PT-Screens werden per
`Navigator.push` geöffnet (wie `TravelEventDetailScreen` und
`AccommodationDetailScreen` auch). Das passt zum bestehenden Muster.

---

## 10. UI-Skizze (Ablauf)

```
TravelScreen (/reisen)
│
├── [FAB: 🚌 ÖPNV suchen]
│   └── PtSearchScreen
│       └── PtSearchResultsScreen
│           └── [Speichern → optional Reise wählen] → Pop to TravelScreen
│
├── [Aktuelle Reisen] ... (unverändert)
├── [Kommende Reisen] ... (unverändert)
├── [ÖPNV-Fahrten]            ← NEU
│   ├── Frankfurt Hbf → München Hbf, 17.07. 10:00
│   ├── Hamburg → Berlin, 18.07. 14:30
│   └── ...
│       └── PtJourneyDetailScreen
│           ├── [Refresh] (Echtzeitdaten)
│           ├── [An Reise anheften] → Trip-Auswahl
│           └── [Löschen]
│
└── [Vergangene Reisen] ... (unverändert)
```

---

## 11. Umsetzungsreihenfolge

- [x] **1. Modelle** (`pt_models.dart`) — alle Datenklassen
- [x] **2. Service** (`pt_service.dart`) — alle API-Aufrufe
- [x] **3. DI** (`app_scope.dart`, `main.dart`, `app.dart`) — Service
      registrieren
- [x] **4. Widgets** (`pt_station_field.dart`, `pt_journey_card.dart`)
- [x] **5. PtSearchScreen** — Suchmaske
- [x] **6. PtSearchResultsScreen** — Suchergebnisse + Speichern
- [x] **7. PtJourneyDetailScreen** — Detail mit Anheften/Löschen/Refresh
- [x] **8. TravelScreen anpassen** — FAB + PT-Sektion + Datenladung
- [ ] **9. Testen** aller Abläufe (manuell, nach API-Bereitstellung)

---

## 12. Offene Punkte / Future

- [ ] **Teilnehmer-Verwaltung:** UI zum Hinzufügen/Entfernen von Teilnehmern
      (API unterstützt `POST/DELETE /participants` bereits)
- [ ] **Abfahrtsplan:** Endpunkt `/stations/{id}/departures` existiert in der
      API, aktuell nicht in der App verwendet
- [ ] **Cron-Job für automatischen Refresh:** API hat `findStaleLegs()`
      vorbereitet, aber kein Cron-Job implementiert
- [ ] **Deep-Linking:** PT-Screens sind nicht per GoRouter erreichbar; bei
      Bedarf als `/reisen/pt/:id` registrieren

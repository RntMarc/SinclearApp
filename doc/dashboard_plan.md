# Dashboard-Plan (Start-Screen / Home)

Das modulare Dashboard für die Start-Seite (`/home`): Nutzer platzieren
vorgefertigte Widgets in fester Reihenfolge, entfernen und hinzufügen sie.
Jedes Widget lädt unabhängig Daten und rendert in fester, vorher bekannter
Größe (Skeleton = Endgröße). V1: scrollende Liste auf Mobile und Desktop,
kein Grid.

Status-Legende: `- [ ]` = offen · `- [x]` = erledigt · `- [~]` = in Arbeit / teilweise.

---

## Entscheidungen (Ergebnis der Klärungsrunde)

- **Edit-Modus-Einstieg:** Stift-Button in der globalen Shell-AppBar, nur auf
  der Route `/home` sichtbar.
- **Umsortieren:** Drag & Drop **und** Hoch/Runter-Pfeile pro Widget.
- **Hinzufügen:** Floating-Action-Button (Plus), der **nur im Edit-Modus**
  sichtbar ist. Öffnet ein Overlay (Bottom-Sheet via `showDesignSheet`, wie
  das mobile Kategorie-Menü). Bereits hinzugefügte Widgets sind ausgegraut.
- **Widget-Einstellungen:** Tipp auf ein Widget **im Edit-Modus** öffnet ein
  Einstellungs-Sheet (Anzahl, Leer-Verhalten).
- **Persistenz:** Lokal jetzt (SharedPreferences), API später — Speicherzugriff
  über ein Gateway-Interface, damit der Umzug auf Server-Endpunkte ohne
  UI-Änderung möglich ist.
- **Leeres Widget:** Nutzer entscheidet **pro Widget** in den Einstellungen:
  `card` = kompakte Leerkarte (gleiche Höhe wie Skeleton, z.B. "Keine
  anstehenden Ausflüge") oder `hide` = nur im Edit-Modus sichtbar (im
  Normal-Modus ausgeblendet).
- **Skeleton-Höhe:** Höhe folgt der **konfigurierten Anzahl** (3 Rezepte = 3
  Zeilen Skeleton). Sie ändert sich nur bei einer Einstellungs-Änderung, nie
  beim Laden. Bei weniger vorhandenen Einträgen bleibt der Platz leer
  (Layout springt nie).
- **Desktop (≥600px):** Gleiche Liste wie Mobile, zentriert mit maximaler
  Breite (Vorschlag: `maxWidth 720`).
- **Tap-Verhalten:** Eintrag → Detail-Route, Titelzeile des Widgets →
  Listen-Route (wie bei Android/iOS-Widgets).
- **Daten-Refresh:** Stale-while-Revalidate: lokaler, persistenter Cache über
  Session-Ende hinweg; beim Öffnen werden alte Daten sofort gerendert, neue
  im Hintergrund geholt und in-place eingepflegt (kein Flackern). Auto-Refresh
  alle **5 Minuten** (Basiswert für alle Widgets); auf Mobile nur im
  Vordergrund (Timer pausiert im Hintergrund, einmaliges Nachladen beim
  erneuten Öffnen, wenn der letzte Refresh länger zurückliegt als das
  Intervall). Pull-to-Refresh lädt alle Widgets parallel neu (reiner
  Datenabruf, UI-Sprungfrei).
- **Nächster Ausflug:** Trips + Standalone-Events gemerged; ein **gerade
  laufender** Ausflug schlägt das nächste zukünftige Event.
- **Planungsdokument:** dieses Dokument.

## Architektur-Überblick

```
lib/features/home/
  dashboard_widget.dart        # enum DashboardWidgetType + Registry
                               # (Titel, Icon, Beschreibung, Defaults, Konfig-Grenzen)
  dashboard_layout.dart        # Layout-Modell + DashboardLayoutStore (Gateway)
                               # + SharedPreferencesDashboardLayoutStore
  dashboard_controller.dart    # ChangeNotifier: Edit-Modus, Layout, Auto-Refresh-Timer,
                               # App-Lifecycle (im AppScope registriert)
  dashboard_cache.dart         # persistenter Daten-Cache pro Widget-Typ
                               # (savedAt + Payload), Stale-while-Revalidate
  dashboard_widget_view.dart   # gemeinsames Gerüst: Header, Skeleton, Leerkarte,
                               # Fehlerkarte, Konfig-Sheet, Drag-Handle
  screens/home_screen.dart     # Normal-Modus (Liste, Pull-to-Refresh) + Edit-Modus
  widgets/                     # 5 Widget-Implementierungen (je eigene Karte + Skeleton):
                               # recipes_widget.dart, agenda_widget.dart,
                               # trip_widget.dart, forum_widget.dart,
                               # payments_widget.dart
```

Ebenen:

1. **Daten:** Jedes Widget besitzt eine eigene, unabhängige Lade-Logik
   (Repository-Methode + Zustand). Kein gemeinsamer Aggregations-Request —
   dadurch blockiert ein langsames Widget die anderen nicht.
2. **Zustand:** `DashboardController` (ChangeNotifier, im AppScope) hält
   Edit-Modus + Layout; jedes Widget hält seinen eigenen Daten-Zustand
   (Muster: `AsyncSection<T>` aus `lib/core/widgets/async_section.dart` bzw.
   das `TripDataController`-Prinzip). Keine neuen State-Management-Pakete.
3. **UI:** Nur Katalog-Widgets aus `lib/design/` (`DesignCard`,
   `DesignGridCard`, `DesignText`, `DesignButton`, `DesignBottomSheet`).
   Widget-Karten und Skeletons sind eigene, im Katalog-Schema dokumentierte
   Widgets — keine lokalen Definitionen im Screen.
4. **Persistenz:** SharedPreferences (bereits eingebunden, web-kompatibel).
   Layout-Schlüssel `beyond.dashboard.layout`, Daten-Cache
   `beyond.dashboard.cache.<type>`.

### Warum der Shell-AppBar-Button über den Controller läuft

Die globale `DesignAppBar` rendert die Shell (`shell_widgets.dart`), also
**außerhalb** des Home-Screens. Ein Bearbeiten-Button, der nur auf `/home`
erscheint, braucht daher Zustand oberhalb der Shell: `DashboardController`
lebt im `AppScope` (wie `AuthService`); die Shell-AppBar fügt bei
`matchedLocation == '/home'` eine `DesignIconButton`-Action hinzu, die den
Edit-Modus toggelt.

## Widget-Katalog (V1)

Gemeinsame Konventionen: Header-Zeile (Titel + ggf. Zähler/Icon), darunter
`count` feste Inhalt-Zeilen. Skeleton = Header-Balken + `count` Zeilen-Balken
(Zeilen-Bild + Textbalken). Bei weniger Einträgen als `count` bleiben Zeilen
leer (Höhe konstant). Einträge sind `DesignCard`-Zeilen mit `onTap`.

| Widget | Typ | Konfig | Datenquelle | Detail-Route |
|---|---|---|---|---|
| Neue Rezepte | `recipes` | Anzahl 2–5, Default 3 | `GET /recipes?sort=created_desc&limit=n` | `/rezepte/:id` · `/rezepte` |
| Kommende Kalender-Events (Agenda) | `calendarAgenda` | Anzahl 1–3, Default 2 | `GET /calendar?start=jetzt&end=jetzt+90d&limit=100`, client-seitig nach `startTime` sortiert (laufende zuerst) | `/kalender/:id` · `/kalender` |
| Nächster Ausflug | `nextTrip` | keine (immer 1 Eintrag) | `GET /trips?limit=100` + `GET /trips/standaloneevents?limit=100`, gemerged: laufender Ausflug bevorzugt, sonst frühester Start | `/reisen/:id` (Trip) · `/reisen` |
| Neue Foren-Beiträge | `forumPosts` | Anzahl 2–5, Default 3 | siehe [API-Anforderung](#api-anforderung-forum-feed) | `/forum/:forumId/beitrag/:postId` · `/forum` |
| Offene Zahlungen | `openPayments` | keine (max. 3 Zeilen) | `GET /subscriptions` (Dedup existiert), Filter `!hasPaid` | `/abos` |

Details:

- **Neue Rezepte:** Zeile = Bild (Thumb), Titel, Kategorie-Badge (ggf.
  ⭐ `avgRating`).
- **Agenda:** Zeile = Startzeit (Tag + Uhrzeit), Titel, Ersteller-Name.
  Laufende Events (Start ≤ jetzt < Ende) werden vor zukünftigen einsortiert.
- **Nächster Ausflug:** Badge "Reise"/"Event", Name, Zeitraum; bei Events
  zusätzlich Ort/Organizer (falls vorhanden). Ein laufender Ausflug gewinnt
  immer.
- **Foren-Beiträge:** Zeile = Forum-Name (Label), Nutzer + relative Zeit,
  Titel/Textausschnitt + Typ-Icon.
- **Offene Zahlungen:** max. 3 Zeilen (Name, Billing-Period-Ende, Preis);
  sind mehr offen, zeigt die dritte Zeile "+X weitere offene Zahlungen"
  (Höhe bleibt konstant). Alle bezahlt → Leer-Verhalten laut Einstellung.

## Edit-Modus

- **Einstieg:** Stift-Action der Shell-AppBar auf `/home`.
- **Zustand im Edit-Modus:**
  - Jede Karte: Drag-Handle links, Hoch/Runter-Pfeile, ✕-Button (entfernen).
  - FAB (Plus) sichtbar → Bottom-Sheet mit allen 5 Widgets aus der Registry;
    bereits hinzugefügte ausgegraut mit Haken ("jedes Widget nur einmal").
  - Tipp auf eine Karte → Einstellungs-Sheet: Anzahl-Stepper (nur wo
    konfigurierbar) + Leer-Verhalten (`card` / `hide`).
  - Entfernen verschiebt nichts: Reihenfolge der restlichen bleibt.
- **Speichern:** Layout wird bei jeder Änderung persistiert; das Verlassen
  des Edit-Modus ändert nur den UI-Zustand (kein Verlustrisiko).

## Daten-Refresh (Stale-while-Revalidate)

- **Kaltstart / erneutes Öffnen:** Widget rendert sofort den Cache (kein
  Skeleton, solange Cache existiert), holt parallel frische Daten und ersetzt
  den Inhalt in-place — kein Flackern, keine Größen-Sprünge.
- **Erster Start ohne Cache:** Skeleton → Daten → inhaltliche Zeilen; Fehler
  → Fehlerkarte mit "Erneut versuchen" (Muster `AsyncSection`), Höhe bleibt.
- **Auto-Refresh:** Timer (5 Minuten, gemeinsamer Grundwert) refresht alle
  Widgets parallel, wieder in-place.
- **App-Lifecycle (Mobile):** `WidgetsBindingObserver` im
  `DashboardController` pausiert den Timer im Hintergrund; beim Zurückkehren
  wird genau einmal nachgeladen, wenn der letzte Refresh älter als das
  Intervall ist.
- **Pull-to-Refresh:** lädt alle Widgets parallel neu, danach in-place
  einpflegen.

## Persistenz (lokal jetzt, API später)

Layout-Schema (`beyond.dashboard.layout`):

```json
{
  "version": 1,
  "widgets": [
    { "type": "recipes", "count": 3, "emptyState": "card" },
    { "type": "calendarAgenda", "count": 2, "emptyState": "card" },
    { "type": "nextTrip", "emptyState": "hide" },
    { "type": "forumPosts", "count": 3, "emptyState": "hide" },
    { "type": "openPayments", "emptyState": "card" }
  ]
}
```

Reihenfolge = Listen-Reihenfolge; entfernt = nicht in der Liste (aus dem
Katalog wieder hinzufügbar). Daten-Cache pro Typ:
`beyond.dashboard.cache.<type>` → `{ "savedAt": ..., "data": ... }`.

**Gateway:** `DashboardLayoutStore` (Interface `load()`/`save()`); heute
SharedPreferences-Impl, später `ApiDashboardLayoutStore` (Vorschlag:
`GET/PUT /dashboard/config`) mit identischer Signatur — der Screen kennt die
Quelle nicht.

## API-Anforderung: Forum-Feed

**Gap:** Es gibt keinen aggregierten Endpunkt über alle Foren; `GET /forums`
liefert zudem kein `isMember`. Client-Fan-out bräuchte 2×N Requests (pro
Forum Detail für `isMember` + Posts).

- [ ] **Empfohlen (SinclearAPI):** `GET /forums/feed?limit=n` — die neuesten
      Beiträge aller Foren des angemeldeten Users, sortiert nach `createdAt`
      absteigend. Antwort pro Eintrag: `forumId`, `forumName`, `postId`,
      `userDisplayName`, `userImage`, `type`, `content`, `commentCount`,
      `upvoteCount`, `createdAt`.
- [ ] **V1-Fallback im Client bis der Endpunkt existiert:** Fan-out über
      `GET /forums` → pro Forum `GET /forums/{id}` (`isMember`) →
      paralleles `GET /forums/{id}/posts?limit=5` → merge + sort +
      `count` nehmen. Der Zugriff läuft hinter einer kleinen Repository-
      Methode, sodass der Umstieg ein Ein-Zeilen-Wechsel ist.
      *Ceiling: N+1-Requests, ok für typische Mitgliedschafts-Zahlen;
      Upgrade-Pfad = `/forums/feed`.*

## Nicht in V1

- Kein Grid-Layout (auch nicht auf Desktop).
- Keine Nutzer-definierten Widget-Größen.
- Keine Server-Synchronisation des Layouts (Gateway bereitet sie vor).
- Kein Widget mit Live-Aktualisierung schneller als 5 Minuten.
- Kein i18n (weiterhin hardcoded Deutsch, wie im gesamten Projekt).

## Umsetzungsschritte

- [ ] Skeleton + Daten: `DashboardCache`, `DashboardLayoutStore`
      (SharedPreferences) inkl. Roundtrip-Test
- [ ] `DashboardWidgetType`-Registry mit Metadaten und Defaults
- [ ] `DashboardController` (Edit-Modus, Timer, Lifecycle) im AppScope
- [ ] Gemeinsames Widget-Gerüst (`dashboard_widget_view.dart`): Header,
      Skeleton (Höhe = Header + `count` Zeilen), Leerkarte, Fehlerkarte,
      Konfig-Sheet, Drag-Handle, Pfeile, ✕
- [ ] Die 5 Widget-Karten mit ihren Repositories (je eigenes AsyncSection-
      Muster, in-place-Refresh)
- [ ] `HomeScreen`: Normal-Modus (Liste, Pull-to-Refresh, Leer-Verhalten
      `card`/`hide`) + Edit-Modus (FAB, Sheet, Drag & Drop + Pfeile,
      Einstellungs-Sheet)
- [ ] Shell-AppBar-Action (Stift) nur für `/home` koppeln an
      `DashboardController`
- [ ] Navigation: Eintrag → Detail, Header → Liste
- [ ] Desktop: zentrierte Liste (`maxWidth 720`)
- [ ] `GET /forums/feed` in SinclearAPI; Fallback-Fan-out ersetzen
- [ ] Tests: Skeleton-Höhen-Regel, Layout-Store, Cache-TTL, Leer-Verhalten,
      Timer-Pausierung, HomeScreen-Widget-Test

## Annahmen / offene Punkte

- `maxWidth 720` für Desktop ist ein Vorschlag; ggf. mit dem Design
  abgleichen.
- Agenda-Fenster `jetzt..jetzt+90d` (angelehnt an `CalendarScreen`);
  Einträge, die im Fenster fehlen, werden einfach nicht angezeigt (Zeilen
  bleiben reserviert).
- Standalone-Event → Detail: Route `/reisen/:id` ist nur für Trips; Verhalten
  für Standalone-Events beim Implementieren gegen den Travel-Screen prüfen
  (ggf. reicht Navigation auf `/reisen`).
- Für `openPayments` gibt es keine Detail-Route (`/abos` ist nur eine Liste);
  Zeilen sind vorerst ohne `onTap`.

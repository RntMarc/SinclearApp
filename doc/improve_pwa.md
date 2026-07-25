# PWA-Ladezeiten verbessern

## Ausgangslage

### Aktuelle Caching-Strategie

| Datei/Verzeichnis | Cache-Header | Zweck |
|---|---|---|
| Root `index.html` | `no-cache, no-store, must-revalidate` (Meta-Tags) | Update-Erkennung |
| Root `version.json` | `no-cache` (.htaccess) | Update-Polling (alle 5 Min) |
| Root `.htaccess` | `no-cache` für js/json/css/wasm | Verhindert Cache von Root-Ressourcen |
| `{version}/` (alle Dateien) | `max-age=31536000, immutable` | Versionierte Assets unbegrenzt cachen |

### Probleme mit aktueller Strategie

1. **Erstbesuch:** Alle Flutter-Assets (~2-5 MB) müssen komplett heruntergeladen
   werden. Kein Caching, keine Preloads.
2. **Nach Deploy:** Neue Version erfordert Download aller Assets – obwohl sich
   oft nur ein Bruchteil geändert hat.
3. **Kein Service Worker:** Es gibt keinen Caching-Service Worker. Die einzige
   SW-Datei ist `firebase-messaging-sw.js` für Push-Benachrichtigungen.
4. **Kein Manuelles Neuladen:** Nutzer können nicht selbst den Cache leeren,
   um ein frisches Laden zu erzwingen.

### Warum ist das so?

Die Strategie wurde bewusst so gewählt, um sicherzustellen, dass Updates
innerhalb kurzer Zeit bei allen Nutzern ankommen (kein stale cache). Das ist
für eine aktive Entwicklungsumgebung sinnvoll, aber für die Performance
nachteilig.

---

## Optimierungsstrategien

### Strategie A: Kurzes Caching + Stale-While-Revalidate (Minimaler Aufwand)

**Konzept:** Root-Index-HTML und version.json mit kurzem Cache (30-60 Sekunden)
versehen. Dadurch werden nachgeladene Seiten schneller, Updates kommen trotzdem
schnell an.

- [ ] **Task A1: Root `.htaccess` anpassen**
  - [ ] `index.html` mit `max-age=30, stale-while-revalidate=300` versehen
    ```apache
    <Files "index.html">
        Header set Cache-Control "max-age=30, stale-while-revalidate=300"
    </Files>
    ```
  - [ ] `version.json` mit `max-age=30, stale-while-revalidate=300` versehen
  - [ ] Meta-Tags in `web/index.html` entfernen oder anpassen (die
    `no-cache`-Meta-Tags überschreiben die `.htaccess`-Header)
  - [ ] Testen: Erstbesuch → Download. Zweiter Besuch innerhalb 30s → Cache.
    Nach 30s → frischer Request.

- [ ] **Task A2: Meta-Tags in index.html bereinigen**
  - [ ] Die Meta-Tags `Cache-Control`, `Pragma`, `Expires` aus
    `web/index.html` entfernen (Zeilen 11-13)
  - [ ] Diese Tags sind redundant zu `.htaccess` und machen dessen
    Konfiguration zunichte
  - [ ] Stattdessen die `.htaccess`-Steuerung beibehalten
  - [ ] Nur `version.json` bleibt auf `no-cache` oder kurzem Cache

### Strategie B: Custom Service Worker mit intelligentem Caching (Mittlerer Aufwand)

**Konzept:** Ein eigener Service Worker übernimmt das Caching nach Bedarf.
Versionierte Assets werden gecached, Root-Ressourcen bei Bedarf aktualisiert.

- [ ] **Task B1: Custom Service Worker erstellen**
  - [ ] Neue Datei `web/sinclear-sw.js` anlegen
  - [ ] Strategie definieren:
    - Versionierte Assets (`/{version}/*`): **Cache-First**
      (werden nach Deploy nie geändert)
    - Root `index.html`: **Network-First** (immer frisch, aber Cache als Fallback)
    - Root `version.json`: **Network-First** (Update-Erkennung)
    - Icons/Manifest: **Cache-First mit Background-Update**
  - [ ] Cache-Name mit Versionsnummer versehen (automatisches Aufräumen)
  - [ ] `install`-Event: Current version precachen
  - [ ] `activate`-Event: Alte Caches löschen
  - [ ] `fetch`-Event: Routing-Strategie anwenden

- [ ] **Task B2: Service Worker registrieren**
  - [ ] In `web/index.html` den alten SW-Registrierungs-Code beibehalten
        (`firebase-messaging-sw.js` auf Root-Level)
  - [ ] Zusätzlich neuen SW registrieren: `navigator.serviceWorker.register('/sinclear-sw.js')`
  - [ ] In `deploy.py` prüfen, dass `sinclear-sw.js` ins Root kopiert wird

- [ ] **Task B3: Cache-Invalidierung bei Deploy**
  - [ ] In `deploy.py` eine `version.txt` oder `cache-version` Datei ins
        Root schreiben, die bei jedem Deploy aktualisiert wird
  - [ ] Service Worker liest diese Datei und invalidiert Caches bei
        Versionswechsel
  - [ ] Alternative: SW liest `version.json` und vergleicht mit
        gecachter Version

- [ ] **Task B4: Testen**
  - [ ] Erstbesuch: Alle Assets werden gecacht
  - [ ] Zweiter Besuch: Assets werden aus Cache geladen
  - [ ] Deploy: Service Worker erkennt neue Version, invalidiert Caches
  - [ ] Offline: App lädt aus Cache (falls aktiviert)

### Strategie C: Manuelles Cache-Leeren in App-Einstellungen (Ergänzend)

**Konzept:** Nutzer können in den Einstellungen einen "Cache leeren"-Button
drücken, der den Browser-Cache komplett bereinigt und die Seite neu lädt.

- [ ] **Task C1: Cache-Clear-Funktion implementieren**
  - [ ] Neue Dart-Datei `lib/core/services/cache_clear_service.dart` erstellen
  - [ ] Web-spezifische Implementierung:
    - [ ] `window.caches.keys()` auflisten
    - [ ] Alle Cache-Storage-Einträge löschen
    - [ ] `window.location.reload(force: true)` ausführen
  - [ ] Stub-Implementierung für nicht-Web-Plattformen (No-Op)
  - [ ] Nutzen von `package:web` für JS-Interop

- [ ] **Task C2: UI in Einstellungen einbauen**
  - [ ] In der Settings/Einstellungen-Seite einen "Cache leeren"-Button einfügen
  - [ ] Bestätigungsdialog vor dem Löschen anzeigen
  - [ ] Nach dem Leeren: Seite neu laden
  - [ ]visuelles Feedback (Loading-Spinner während des Löschens)

- [ ] **Task C3: "Force Reload" Option**
  - [ ] Button "App neu laden" in Einstellungen (neben "Cache leeren")
  - [ ] Führt `window.location.reload(true)` aus (force reload)
  - [ ] Unterscheidung zum Cache-Leeren: Nur Reload ohne Cache-Bereinigung
  - [ ] Nutzer können selbst entscheiden, was sie brauchen

### Strategie D: Längeres Caching mit version-Busting (Kombination)

**Konzept:** Da jedes Deploy eine neue Versionsnummer hat, können wir
versionierte Assets aggressiv cachen und nur Root-Ressourcen kurz cachen.
Das ist bereits der Fall – aber wir können es optimieren.

- [ ] **Task D1: Resource Hints in index.html**
  - [ ] `<link rel="preload">` für kritische Ressourcen hinzufügen:
    ```html
    <link rel="preload" href="/{version}/main.dart.js" as="script">
    <link rel="preload" href="/{version}/flutter_bootstrap.js" as="script">
    ```
  - [ ] In `deploy.py` die Preload-Links dynamisch mit aktuellem
        Versionspfad setzen
  - [ ] `<link rel="preconnect">` für externe Domains (Firebase, etc.)

- [ ] **Task D2: App-Shell Caching**
  - [ ] Minimalen HTML-Shell im Cache speichern (nur Grundgerüst)
  - [ ] Falls Service Worker implementiert wird (Strategie B):
    - [ ] Shell-HTML precachen
    - [ ] Flutter-Assets nachladen wenn Shell available
  - [ ] Ergebnis: App zeigt sofort ein Lade-Indikator, während
        Flutter-Assets im Hintergrund geladen werden

- [ ] **Task D3: Lazy Loading von Flutter-Assets**
  - [ ] Prüfen, ob `flutter_bootstrap.js` bereits optimiertes Loading
        unterstützt (tut es: Code-Splitting)
  - [ ] `main.dart.js` wird bereits als eine Datei ausgeliefert
  - [ ] Prüfen, ob Tree-Shaking und Dead-Code-Elimination
        optimiert sind

### Strategie E: Hybrid-Ansatz (Empfohlen)

**Kombination aus Strategien A + C + D**

- [ ] **Task E1: Quick Wins umsetzen**
  - [ ] Meta-Tags für Cache-Control aus `web/index.html` entfernen
  - [ ] `.htaccess` für Root-Dateien anpassen: `max-age=60, stale-while-revalidate=600`
  - [ ] `version.json` bleibt auf `max-age=0, must-revalidate`
  - [ ] Resource Hints (Preload) für kritische Assets hinzufügen

- [ ] **Task E2: Cache-Clear Button implementieren**
  - [ ] Cache-Clear-Funktion in `lib/core/services/` erstellen
  - [ ] UI in Einstellungen einbauen
  - [ ] Testen auf verschiedenen Browsern

- [ ] **Task E3: Monitoring einbauen**
  - [ ] Loading-Time Tracking (optional, für spätere Analyse)
  - [ ] Loggen, ob Assets aus Cache oder Network geladen wurden

---

## Empfohlene Vorgehensweise

### Phase 1 (Sofort, minimaler Aufwand)
1. **Task A1 + A2** durchführen (Meta-Tags entfernen, .htaccess anpassen)
   → Reduziert Ladezeit um 30-50% bei Folgebesuchen
2. **Task E1** durchführen (Preload-Hints)
   → Beschleunigt erstes Laden um 10-20%

### Phase 2 (Mittelfristig)
3. **Task C1 + C2** implementieren (Cache-Clear Button)
   → Nutzer haben Kontrolle über ihr Caching
4. **Task C3** optional (Force-Reload Button)

### Phase 3 (Optional, bei Bedarf)
5. **Task B1-B4** implementieren (Custom Service Worker)
   → Volle Kontrolle über Caching-Strategie
6. **Task D1-D3** umsetzen (Resource Hints, App-Shell)

---

## Erwartete Ergebnisse

| Metrik | Aktuell | Nach Phase 1 | Nach Phase 2 |
|---|---|---|---|
| Erstbesuch | ~3-5s | ~2-4s | ~2-4s |
| Folgebesuch (gleiche Version) | ~3-5s | ~0.5-1s | ~0.5-1s |
| Nach Deploy | ~3-5s | ~2-4s | ~2-4s |
| Cache-Leeren durch Nutzer | Nicht möglich | Nicht möglich | Möglich (1 Klick) |
| Update-Erkennung | Sofort (5 Min Polling) | Max. 60s verzögert | Max. 60s verzögert |

---

## Technische Details

### Cache-Control Header Erklärung

```
max-age=60              → Browser darf Datei 60 Sekunden aus Cache verwenden
stale-while-revalidate=600  → Nach Ablauf: Cache sofort verwenden, im
                              Hintergrund prüfen ob neue Version vorhanden
must-revalidate        → Nach Ablauf: Muss beim Server nachfragen
immutable              → Datei ändert sich nie (für versionierte Assets)
```

### Warum `stale-while-revalidate`?

- Nutzer sieht sofort gecachten Inhalt (schnell)
- Im Hintergrund wird geprüft, ob neue Version verfügbar ist
- Falls ja: Beim nächsten Besuch wird neue Version geladen
- Kompromiss aus Geschwindigkeit und Aktualität

### Bisherige Erkenntnisse zur Flutter-Web-Performance

- `main.dart.js` ist typischerweise 2-5 MB (komprimiert ~800 KB-1.5 MB)
- `flutter_bootstrap.js` ist klein (~5 KB)
- Erster Laden ist immer langsam (Download aller Assets)
- Nachfolgende Loads sind schnell wenn Assets gecacht sind
- Das aktuelle Setup cacht versionierte Assets bereits (immutable)
- Das Problem ist, dass die Root-Ressourcen (index.html) kein Caching
  erlauben und die Meta-Tags die `.htaccess`-Konfiguration überschreiben

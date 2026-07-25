# PWA-Probleme beheben

## Diagnose

### Kernproblem: PWA lädt nicht nach Installation

Die PWA kann installiert werden, aber beim Öffnen bleibt die Seite weiß/leer.

**Ursache:** Das `manifest.json` (im versionierten Verzeichnis `/0.7.1/`) hat
`"start_url": "."`. Da das Manifest unter `/0.7.1/manifest.json` liegt, resolved
`"."` zu `/0.7.1/`. Dort existiert zwar ein `index.html` (vom Flutter-Build
kopiert), aber dieses hat `<base href="/">` (Flutter-Default). Dadurch versucht
der Browser, Flutter-Assets wie `main.dart.js` vom Root (`/`) zu laden – dort
existieren sie aber nicht. → PWA kann nicht starten.

### Sekundäres Problem: Manifest im versionierten Verzeichnis

Das gesamte Manifest inkl. Icons liegt im versionierten Verzeichnis. Nach einem
Deploy wird das alte Verzeichnis nach 30+ Tagen gelöscht.utzer mit alter
PWA-Installation haben dann ein gecachtes Manifest, das auf nicht mehr
existierende Pfade zeigt.

### Deploy-Struktur (aktuell)

```
/
├── index.html          (base href="/{version}/", kein Cache)
├── version.json        (kein Cache)
├── .htaccess           (no-cache für js/json/css/wasm im Root)
├── firebase-messaging-sw.js
└── {version}/
    ├── index.html      (Flutter-Build, base href="/")
    ├── main.dart.js
    ├── flutter_bootstrap.js
    ├── manifest.json   (immutable Cache)
    └── icons/          (immutable Cache)
```

---

## Tasks

### Task 1: `start_url` in manifest.json auf absoluten Pfad setzen
- [x] In `web/manifest.json` `start_url` von `"."` auf `"/"` ändern
- [x] Ebenso `scope` auf `"/"` setzen (explizit, obwohl Default "/")
- [x] `id` auf `"/"` setzen (stabilisiert die PWA-Identifikation)
- [x] Prüfen, ob deploy.py das manifest.json aus dem Flutter-Build
      überschreibt (tut es nicht – `copytree` kopiert Flutter-Build inkl.
      `web/manifest.json`, aber `web/manifest.json` ist die Quelle)
- [ ] Deploy durchführen und testen:
      - Website unter Root-URL öffnen → funktioniert
      - Als PWA installieren → Icon im Startmenü erscheint
      - PWA öffnen → lädt korrekt
      - Nach neuem Deploy: alte PWA-Installation zeigt neuen Inhalt

### Task 2: Root-Level manifest.json und Icons (robuste Lösung)
- [x] `web/manifest.json` Icons auf absolute Pfade ändern
      (`"src": "/icons/..."` statt relativ)
- [x] In `deploy.py` `post_process_web()` anpassen:
  - [x] Manifest aus dem versionierten Build ins Root kopieren
  - [x] Icons-Verzeichnis ins Root kopieren
- [x] In `web/index.html` den Manifest-Link auf absoluten Pfad setzen:
      `<link rel="manifest" href="/manifest.json">`
- [x] Icons aus `copytree` des versionierten Builds ausschließen
      (`ignore=shutil.ignore_patterns('manifest.json', 'icons')`)
- [x] Deploy-Struktur nach Anpassung:
  ```
  /
  ├── index.html          (base href="/{version}/")
  ├── manifest.json       (ROOT, kein Version-Pfad)
  ├── icons/              (ROOT)
  ├── version.json
  ├── .htaccess
  ├── firebase-messaging-sw.js
  └── {version}/
      ├── main.dart.js
      ├── flutter_bootstrap.js
      └── ...
  ```
- [ ] Testen:
      - PWA-Installation zeigt keine versionierte URL mehr
      - Icons werden korrekt angezeigt
      - Nach Deploy: neues Manifest wird geladen

### Task 3: Alte versionierte Manifeste/Icons aufräumen
- [x] Versionierte `manifest.json` und `icons/` per
      `shutil.ignore_patterns()` vom `copytree` ausgeschlossen
- [ ] Deploy-Skript testen (Dry-Run reicht)

### Task 4: Firebase Service Worker korrekt positionieren
- [x] `firebase-messaging-sw.js` muss im Root bleiben (Scope `/`)
- [x] Version-Busting in deploy.py geprüft: `?v=version+versionCode`
      wird korrekt an den SW-Registrierungs-Pfad angehängt
- [x] Aktueller Code in deploy.py ist korrekt

### Task 5: Bestehende PWA-Installationen reparieren
- [x] **Wichtig:** Nutzer mit bestehender PWA müssen nach dem Deploy
      einmal `domain.de/` im Browser öffnen. Das lädt das neue Manifest
      mit `start_url: "/"`. Anschließend alte PWA deinstallieren und
      neu installieren.
- [x] Die alte SW-Registrierung (`firebase-messaging-sw.js`) wird durch
      das Version-Busting automatisch aktualisiert.
- [ ] Optional: Im App-Code nach dem Laden prüfen, ob alte Caches der
      versionierten Verzeichnisse existieren und bereinigen.

### Task 6: Test-Szenarien definieren und ausführen
- [ ] Test 1: Website im Browser öffnen → lädt korrekt
- [ ] Test 2: Als PWA installieren → Icon erscheint
- [ ] Test 3: PWA öffnen → lädt korrekt, keine weiße Seite
- [ ] Test 4: PWA schließen und erneut öffnen → lädt aus Cache
- [ ] Test 5: `python deploy.py --dry-run` → prüft Ausgabe
- [ ] Test 6: Deploy durchführen (neue Version)
- [ ] Test 7: PWA nach Deploy öffnen → zeigt neuen Inhalt
- [ ] Test 8: Alte Version auf Server prüfen → wurde aufgeräumt
- [ ] Test 9: Firebase Notifications funktionieren

# Redesign: Mobile Navigation mit PageView & zweischichtiger Bottom Nav

## Regeln

1. **Status-Codes**: Jeder Task und Sub-Task beginnt mit `- [ ]`. Nach der
   Ausführung wird der Haken durch ein **A** ersetzt, also `- [A]`. Erst bei
   einer explizit angeforderten **Revalidierung** werden alle Tasks und
   Sub-Tasks erneut geprüft und das **A** durch ein **R** ersetzt, also
   `- [R]`, wenn der Task bei der Revalidierung noch korrekt ist.
2. **Abschluss**: Nachdem alle Tasks auf **A** gesetzt sind, ist der Vorgang
   **beendet**. Es werden keine weiteren Änderungen vorgenommen, bis eine
   erneute Aufforderung zur Revalidierung eingeht.

---

## Tasks

### 1. `lib/features/shell/shell_page_config.dart` anlegen

- [A] Datei `shell_page_config.dart` im Ordner `lib/features/shell/` anlegen
- [A] `ShellNavCategory`-Enum importieren/übernehmen (aus `shell_widgets.dart`)
- [A] Klasse `ShellPageEntry` definieren mit Feldern: `label` (String), `icon` (IconData), `route` (String?, null bei Platzhaltern), `category` (ShellNavCategory), `isPlaceholder` (bool)
- [A] Konstante `List<ShellPageEntry> allPages` – lineare Ordnung aller 16 Seiten:
      - Index 0: Design Showcase (System)
      - Index 1: Einstellungen (System)
      - Index 2: Admin – Platzhalter (System)
      - Index 3: Feedback (System)
      - Index 4: Changelog – Platzhalter (System)
      - Index 5: Forum (Gemeinschaft)
      - Index 6: Kritik – Platzhalter (Gemeinschaft)
      - Index 7: Rezepte (Gemeinschaft)
      - Index 8: Fotos – Platzhalter (Gemeinschaft)
      - Index 9: Kontakte (Gemeinschaft)
      - Index 10: Home (Start)
      - Index 11: Entdecken (Unterwegs)
      - Index 12: Reisen (Unterwegs)
      - Index 13: Kalender (Organisation)
      - Index 14: Umfrage – Platzhalter (Organisation)
      - Index 15: Abos (Organisation)
- [A] `Map<ShellNavCategory, List<int>> pagesByCategory` – jeder Kategorie ihre Indices zuordnen
- [A] `ShellNavCategory categoryForPageIndex(int index)` – Kategorie eines Index ermitteln
- [A] `int? pageIndexForLocation(String location)` – Route → PageView-Index:
      - Exakter Match (z. B. `/home` → 10)
      - Prefix-Match für Sub-Routen (z. B. `/einstellungen/profil` → 1)
      - `null` bei Detail-Routen (z. B. `/entdecken/123`, `/forum/456/beitrag/789`)
- [A] `int firstPageInCategory(ShellNavCategory category)` – erste Seite einer Kategorie
- [A] `String shellTitleForPageIndex(int index)` – Titel aus `shellTitleForLocation` refaktorieren

### 2. `lib/features/shell/widgets/shell_sub_page_nav.dart` anlegen

- [A] Datei `shell_sub_page_nav.dart` im Ordner `lib/features/shell/widgets/` anlegen
- [A] Widget `ShellSubPageNav` als `StatelessWidget`:
      - Parameter: `ShellNavCategory category`, `int activePageIndex`, `void Function(int) onPageTap`
      - Baut aus `pagesByCategory[category]` die Pill-Chips
      - Jede Pill: ca. 24px hoch, horizontales Padding 12px, abgerundet
        - Aktiv: Hintergrund in Primärfarbe, Text weiß
        - Inaktiv: Outline (1px border), transparent, Text in `textLow`
        - Platzhalter: ausgegraut, `onTap: null`
      - Horizontale `ListView` mit den Pills
- [A] Container-Höhe auf ~32px setzen (ohne zusätzliches Padding außen)
- [A] Trenner (dünne Linie) zur darunterliegenden Kategorie-Nav einziehen

### 3. `lib/features/shell/widgets/shell_widgets.dart` refaktorieren

- [A] `ShellCategorySheet`-Klasse entfernen (wird nicht mehr benötigt)
- [A] `ShellSheetItem`-Klasse entfernen (wird nicht mehr benötigt)
- [A] `_showCategorySheet`-Methode aus `ShellMobileBottomNav` entfernen
- [A] `ShellMobileBottomNav._onTap` vereinfachen: jeder Tab ruft `context.go(firstPageInCategory(category))` auf
- [A] Platzhalter-Seiten-Widgets definieren (einfaches zentriertes Layout mit Icon + "Bald"-Badge)
- [A] `ShellMobile` von `StatelessWidget` auf `StatefulWidget` umstellen:
      - `PageController _pageController` (initialisiert mit `pageIndexForLocation` der aktuellen Route)
      - `int _currentPageIndex`
      - `_syncPageWithRoute()` – liest `GoRouterState.of(context).matchedLocation` und springt per `_pageController.jumpToPage()`
      - Aufruf von `_syncPageWithRoute()` in `initState` und bei jedem `build` (Location-Vergleich)
- [A] `ShellMobile.build` umbauen:
      - `GoRouterState.of(context).matchedLocation` lesen
      - `pageIndexForLocation(location)`:
        - **`!= null`** (Root-Route): 
          ```dart
          Column(
            DesignAppBar(title: shellTitleForPageIndex(_currentPageIndex)),
            Expanded(
              PageView.builder(
                controller: _pageController,
                itemCount: allPages.length,
                itemBuilder: (context, index) => _buildPage(index),
              ),
            ),
            ShellSubPageNav(...),
            ShellMobileBottomNav(...),
          )
          ```
        - **`== null`** (Detail-Route):
          ```dart
          Column(
            DesignAppBar(title: shellTitleForLocation(location)),
            Expanded(child: widget.child), // von ShellRoute
            ShellSubPageNav(...), // beide Reihen sichtbar
            ShellMobileBottomNav(...),
          )
          ```
- [A] `PageView.builder` implementieren mit `itemBuilder`:
      - Echte Seiten: per `allPages[index].route` den passenden Screen bauen
      - Platzhalter-Seiten: das Platzhalter-Widget rendern
      - `AutomaticKeepAliveClientMixin` auf jeder Seite für lazy keepAlive
- [A] `onPageChanged`-Callback am `PageView`: `_currentPageIndex` setzen + `context.go(allPages[_currentPageIndex].route)`
- [A] Zirkulären Wrap implementieren:
      - Wenn `_currentPageIndex == allPages.length - 1` und swipe right → `_pageController.jumpToPage(0)`
      - Wenn `_currentPageIndex == 0` und swipe left → `_pageController.jumpToPage(allPages.length - 1)`
      - Nutzt `PageController` mit `viewportFraction`-Logik oder `onPageChanged`-Detektion

### 4. Route-Syncing & Edge Cases prüfen

- [A] Route-Sync: Bei GoRouter-Locations-Wechsel (z. B. Browser-Back) springt PageView zur richtigen Seite
- [A] Detail-Routen (z. B. `/entdecken/123`): PageView unsichtbar, `widget.child` sichtbar, Nav bleibt
- [A] Sub-Routen (z. B. `/einstellungen/profil`): Sub-Page-Reihe zeigt Einstellungen-Pill aktiv
- [A] Platzhalter-Seiten: erscheinen im PageView, sind nicht interaktiv, zeigen "Bald"-Badge
- [A] Zirkulärer Wrap an den Enden funktioniert sauber (Index 0 ↔ Index 15)
- [A] AppBar-Titel wechselt korrekt bei PageView-Swipe
- [A] Desktop (≥600px) bleibt unverändert (Sidebar wie gehabt)

### 5. Lint & Analyse

- [A] `dart format lib/features/shell/` ausführen
- [A] `flutter analyze` läuft ohne Fehler durch

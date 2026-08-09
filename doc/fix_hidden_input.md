# Tastatur-Überlagerung bei Eingabefeldern beheben (Keyboard Avoidance)

Dieses Dokument dokumentiert das Problem verdeckter Eingabefelder auf Smartphones, analysiert verschiedene Ansätze von Stack Overflow und beschreibt die gewählte Implementierung.

## Das Problem

Auf mobilen Touch-Geräten (Android & iOS) überlagerert die virtuelle Tastatur oft das untere Drittel bis die Hälfte des Bildschirms. Wenn sich ein Eingabefeld in diesem Bereich befindet, wird es standardmäßig von der Tastatur verdeckt, sodass der Nutzer nicht sieht, was er eingibt.

In Flutter wird dieses Verhalten normalerweise über das `resizeToAvoidBottomInset` Flag des `Scaffold`-Widgets gesteuert. Da die Sinclear-App jedoch auf vielen Seiten (z.B. Beitragserstellung im Forum, Rezepterstellung, etc.) eine verschachtelte Shell-Navigation verwendet (`ShellMobile`), und dieses Shell-Navigations-Widget direkt ein `DesignSurface` (ohne eigenes `Scaffold`) zurückgegeben hat, konnte das Framework die Ansicht nicht automatisch verkleinern. Dadurch „wussten“ die untergeordneten Scrollviews nicht, dass ihr sichtbarer Bereich kleiner geworden ist, und konnten das aktive Textfeld nicht hochscrollen.

---

## Analysierte Lösungsansätze von Stack Overflow

Bei der Recherche wurden folgende gängige Möglichkeiten untersucht, um dieses Verhalten zu lösen:

### Option 1: Scaffold mit `resizeToAvoidBottomInset: true` (Gewählte Lösung) ⭐
* **Beschreibung:** Der gesamte mobile Screen (in `ShellMobile`) wird in ein `Scaffold` gehüllt, welches das Attribut `resizeToAvoidBottomInset: true` besitzt.
* **Vorteile:** Standardverhalten des Frameworks auf Systemebene. Verringert die Viewport-Größe bei Tastatureinblendungen automatisch, sodass alle verschachtelten Scrollviews (z.B. in der Forums-Beitragserstellung oder Rezepterstellung) nativ reagieren und fokussierte Textfelder hochscrollen.
* **Nachteile:** Keine. Dies ist der sauberste und robusteste Ansatz, da er direkt auf Flutter-Framework-Ebene ansetzt.

### Option 2: `flutter_screenutil` Konfigurationsanpassung
* **Beschreibung:** Wrap von `MaterialApp` in ein `ScreenUtilInit` mit `useInheritedMediaQuery: true`.
* **Vorteile:** Behebt Rebuild-Probleme, wenn ScreenUtil die Medienabfragen abfängt.
* **Nachteile:** Sinclear nutzt das `flutter_screenutil`-Paket aktuell nicht, weshalb dieser Ansatz nicht anwendbar ist und ein neues Paket vermieden werden sollte.

### Option 3: Dynamischer Abstandshalter am Ende des Scrollviews
* **Beschreibung:** Platzieren eines leeren Containers/SizedBox am Ende einer Column in einem `SingleChildScrollView`, dessen Höhe sich nach `MediaQuery.of(context).viewInsets.bottom` richtet.
* **Vorteile:** Ermöglicht das Hochscrollen über die normalen Inhaltsgrenzen hinaus.
* **Nachteile:** Muss für jeden einzelnen Formular-Screen manuell implementiert und gepflegt werden, was redundant und fehleranfällig ist.

### Option 4: Dynamisches Padding auf Eingabefeld-Ebene
* **Beschreibung:** Das `DesignTextField` wird in ein `AnimatedPadding` gehüllt, das nur im fokussierten Zustand und bei geöffneter Tastatur ein unteres Padding in Höhe der Tastatur anwendet.
* **Nachteile:** Führt zu unerwünschten vertikalen Layoutverschiebungen anderer Felder innerhalb von Formularen und kann in fest begrenzten Containern (z.B. Dialogen) zu Render-Overflow-Fehlern führen.

---

## Implementierungsdetails

Die gewählte **Option 1** wurde implementiert:

1. In `lib/features/shell/widgets/shell_widgets.dart` wurde das `ShellMobile`-Widget in ein `Scaffold` mit `resizeToAvoidBottomInset: true` gehüllt.
2. Im zentralen Widget `DesignTextField` (`lib/design/widgets/primitives/design_text_field.dart`) wurde das komfortable `scrollPadding` auf `EdgeInsets.only(bottom: 140.0)` gesetzt.

Dadurch schrumpft der sichtbare Viewport der App auf Betriebssystemebene, sobald die virtuelle Tastatur erscheint. Die untergeordneten Formular-Scrollviews erkennen die geänderte Höhe sofort und scrollen das aktive `DesignTextField` dank des großzügigen `scrollPadding`s von `140.0` Pixeln elegant und nativ über die Tastaturgrenze hinaus in den Fokus des Nutzers.

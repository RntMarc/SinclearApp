# Tastatur-Überlagerung bei Eingabefeldern beheben (Keyboard Avoidance)

Dieses Dokument dokumentiert das Problem verdeckter Eingabefelder auf Smartphones, analysiert verschiedene Ansätze von Stack Overflow und beschreibt die gewählte Implementierung.

## Das Problem

Auf mobilen Touch-Geräten (Android & iOS) überlagert die virtuelle Tastatur oft das untere Drittel bis die Hälfte des Bildschirms. Wenn sich ein Eingabefeld in diesem Bereich befindet, wird es standardmäßig von der Tastatur verdeckt, sodass der Nutzer nicht sieht, was er eingibt.

In Flutter wird dieses Verhalten normalerweise über das `resizeToAvoidBottomInset` Flag des `Scaffold`-Widgets gesteuert. Da die Sinclear-App jedoch auf vielen Seiten (z.B. Beitragserstellung im Forum, Rezepterstellung, etc.) eine verschachtelte Shell-Navigation verwendet und dort direkt ein `DesignSurface` (ohne eigenes Scaffold) zurückgegeben wird, kann das Framework die Ansicht nicht automatisch verkleinern. Dadurch „weiß“ die Scrollview nicht, dass ihr sichtbarer Bereich kleiner geworden ist, und scrollt das aktive Textfeld nicht hoch.

---

## Analysierte Lösungsansätze von Stack Overflow

Bei der Recherche wurden folgende gängige Möglichkeiten untersucht, um dieses Verhalten zu lösen:

### Option 1: Scaffold mit `resizeToAvoidBottomInset: true`
* **Beschreibung:** Der gesamte Screen wird in ein `Scaffold` gehüllt, welches das Attribut `resizeToAvoidBottomInset: true` besitzt.
* **Vorteile:** Standardverhalten des Frameworks.
* **Nachteile:** Funktioniert nicht zuverlässig, wenn kein eigenständiges Scaffold auf Page-Ebene vorhanden ist (wie bei unseren Pages, die innerhalb der Shell gerendert werden). Ein Scaffold pro Screen einzuführen, würde die gesamte Navigations- und Shell-Struktur verändern. Der Admin lehnt diesen Ansatz ab.

### Option 2: `flutter_screenutil` Konfigurationsanpassung
* **Beschreibung:** Wrap von `MaterialApp` in ein `ScreenUtilInit` mit `useInheritedMediaQuery: true`.
* **Vorteile:** Behebt Rebuild-Probleme, wenn ScreenUtil die Medienabfragen abfängt.
* **Nachteile:** Keine. Vom Admin präferiert.

### Option 3: Dynamischer Abstandshalter am Ende des Scrollviews
* **Beschreibung:** Platzieren eines leeren Containers/SizedBox am Ende einer Column in einem `SingleChildScrollView`, dessen Höhe sich nach `MediaQuery.of(context).viewInsets.bottom` richtet.
* **Vorteile:** Ermöglicht das Hochscrollen über die normalen Inhaltsgrenzen hinaus.
* **Nachteile:** Muss für jeden einzelnen Formular-Screen manuell implementiert und gepflegt werden, was redundant und fehleranfällig ist.

### Option 4: Dynamisches Padding auf Eingabefeld-Ebene (Gewählte Lösung) ⭐
* **Beschreibung:** Das `DesignTextField` wird in ein `AnimatedPadding` gehüllt, das nur im fokussierten Zustand (`_focused == true`) und bei geöffneter Tastatur (`viewInsets.bottom > 0`) ein unteres Padding in Höhe der Tastatur (`MediaQuery.of(context).viewInsets.bottom`) anwendet.
* **Code-Muster:**
  ```dart
  final keyboardHeight = MediaQuery.maybeOf(context)?.viewInsets.bottom ?? 0;
  final double bottomPadding = (_focused && keyboardHeight > 0) ? keyboardHeight : 0.0;

  return AnimatedPadding(
    duration: const Duration(milliseconds: 150),
    curve: Curves.easeOut,
    padding: EdgeInsets.only(bottom: bottomPadding),
    child: Container( ... ),
  );
  ```
* **Vorteile:**
  * Funktioniert **global** für alle Felder, die auf `DesignTextField` basieren.
  * Löst das Problem direkt auf **Eingabefeld-Widget-Ebene**, wie vom Benutzer gewünscht.
  * Keine permanenten visuellen Verlängerungen (Padding ist nur aktiv, wenn fokussiert und Tastatur offen).
  * Erfordert keine Änderung an der Scaffold- oder Shell-Architektur.
  * Äußerst flüssige Animation über `AnimatedPadding`.
* **Nachteile:** Hat beim ersten Versuch nicht funktioniert. Muss erneut getestet werden.

---

## Implementierungsdetails

Die gewählte **Option 4** wurde direkt im zentralen Widget `DesignTextField` (`lib/design/widgets/primitives/design_text_field.dart`) implementiert.

Sobald ein Eingabefeld den Fokus erhält und die Bildschirmtastatur aufsteigt, vergrößert sich das untere Padding des fokussierten Feldes dynamisch um die genaue Pixelhöhe der Tastatur. Da sich das Feld in einer Scrollview (`SingleChildScrollView` oder `ListView`) befindet, dehnt sich der Scrollbereich nach unten aus, und Flutter scrollt das Eingabefeld automatisch perfekt über die Tastatur. Sobald das Feld den Fokus verliert oder die Tastatur geschlossen wird, schrumpft das Padding wieder fließend auf `0.0`.

# SPEC-004 — ManualShelf 1.3.1: Ein Tipp irgendwo in die Zeile öffnet das Manual

**Status:** Gebaut auf main, wartet auf Christians Gerätetest · **Bau:** Kai · **Abnahme:** Christian
**Version:** 1.3.1 (Fehlerbehebung ⇒ Patch), Tag `v1.3.1` erst nach Christians Abnahme

## 1. Anlass

Christian (08.11.2026): In der Hauptansicht (Liste der Manuals) öffnet sich ein Manual nur über den kleinen Pfeil
rechts. Ein Tipp irgendwo in das Feld des Manuals soll es öffnen.

## 2. Ursache (gemessen auf main `b81e32e`)

- Die Zeile ist ein `NavigationLink` um die ganze `ManualRow` (`FetchedManualsDisplayView.swift:55–58`); der Link
  deckt die ganze Zeile ab [HOCH, Accessibility-Baum: Button-Rahmen = Zellenrahmen].
- Die Tag-Chips liegen in einer horizontalen `ScrollView` (`FetchedManualsDisplayView.swift:110`), die die volle
  Zeilenbreite zwischen Titel und Datumszeile einnimmt — auch bei nur einem Tag. Eine ScrollView nimmt Tipps selbst
  an und gibt sie nicht an den Link weiter; `.allowsHitTesting(false)` an den Chips hilft nicht, weil die ScrollView
  darunter den Tipp fängt [HOCH, UI-Test].
- Messung per UI-Test (Tipps per Bildschirmkoordinate, iPhone 18 Pro und iPad Pro 11" mit iOS 27.2):
  Titel, Vorschaubild und freie Fläche neben dem Titel öffnen das Manual; Tipp auf einen Chip und auf die freie
  Fläche im Tag-Band öffnen **nichts** — auf beiden Geräten gleich [HOCH].
- Manuals **ohne** Tags waren nicht betroffen. Wer Tags nutzt, trifft mit einem Tipp in die Zeilenmitte genau das
  Band; der Pfeil (iPhone) liegt außerhalb und funktioniert immer — daher der Eindruck „nur der Pfeil“ [MITTEL].
- Geprüft und verworfen: `.buttonStyle(PlainButtonStyle())` am Link ist nicht die Ursache; ohne ihn fängt das
  Band die Tipps genauso [HOCH, UI-Test].
- Mac („Designed for iPad“) nutzt dieselbe Ansicht; dort konnte ich die App ohne Signatur nicht starten
  ⇒ Gerätetest.

## 3. Entscheid

- **Kai (erster Bau):** Tags ohne ScrollView, solange sie in eine Zeile passen (`ViewThatFits`); bei Überlauf blieb
  die ScrollView zum seitlichen Wischen. Dort fing das Band weiter Tipps — Konflikt an Christian gemeldet.
- **Entscheid Christian 08.11.: Umbruch in zusätzliche Zeile.** Passen die Tags nicht in eine Zeile, brechen sie in
  so viele weitere Zeilen um wie nötig (eigenes `FlowLayout`, SwiftUI-`Layout`, kein Fremd-Paket). Kein seitliches
  Wischen, keine ScrollView im Tag-Band, keine Deckelung und kein „+n“. Damit öffnet ein Tipp irgendwo in der Zeile
  immer das Manual. Kommt mit in 1.3.1.
- Ein einzelner Tag, der breiter ist als die Zeile, wird auf die Zeilenbreite gekürzt (einzeilig mit „…“).
- Unverändert: Wischen zum Löschen, „Bearbeiten“, Vorschaubild, Tag-Farben, Datumszeile.

## 4. Abnahme

- Swift 6, Debug und Release, Simulator und Mac („Designed for iPad“): 0 Warnungen; alle Tests grün.
- UI-Test `ManualListRowTapUITests`: Tipp auf Titel, Vorschaubild, freie Fläche neben dem Titel, Chip, freie
  Fläche im Tag-Band und — bei umgebrochenen Tags — die zweite Tag-Zeile öffnet das Manual (iPhone und iPad).
- Gerätetest durch Christian (iPhone, iPad, Mac).

## 5. Verlauf

- 08.11.2026: Messung, Fix und Spec (Kai). Für den UI-Test startet die App im Debug-Build mit dem Argument
  `-uiTestSampleData` auf den In-Memory-Beispieldaten der Vorschau (nie der echte Speicher, kein CloudKit-Abgleich);
  die Beispieldaten haben dafür ein Tag „Küche“ am ersten Manual. Gegenprobe: ohne Fix scheitern die beiden
  Tag-Band-Tests, mit Fix sind alle fünf grün.
- 08.11.2026: gebaut (Kai): Fix + UI-Test (`8f032e0`), Version 1.3.1 (`e22e84a`).
  - Tests: alle Unit- und UI-Tests grün auf iPhone 18 Pro und iPad Pro 11" (iOS 27.2), davon 5 neue in
    `ManualListRowTapUITests`. Debug und Release, Simulator und Mac („Designed for iPad“): 0 Warnungen.
    String Catalog unverändert (keine neuen Texte).
  - Geprüft unverändert: Wischen zum Löschen, „Bearbeiten“-Modus (Screenshots iPhone/iPad). Ein Kontextmenü hat die
    Listenzeile nicht. Langes Drücken öffnete nach dem Fix das Manual; vor dem Fix nicht gemessen (Korrektur:
    hier stand zuerst „wie bisher“).
  - Mac: gebaut, unsigniert nicht startbar ⇒ Gerätetest.
- 08.11.2026: Christian entscheidet den Konflikt aus §3: Umbruch in zusätzliche Zeilen statt Wischen, in 1.3.1.
  Gebaut (Kai): `FlowLayout` ersetzt `ViewThatFits`/ScrollView. Beispieldaten: „Beispiel-Manual 1“ mit 8 Tags,
    weiterhin nur im Speicher, ohne CloudKit. Neuer UI-Test `testTapOnSecondTagLineOpensManual` prüft, dass die
    Tags umbrechen (Band ≥ 1,5 × einzeilig) und ein Tipp in die zweite Tag-Zeile das Manual öffnet.
  - Tests: alle 52 Testfunktionen grün auf iPhone 17 und iPad Pro 11" (iOS 27.2). Debug und Release,
    Simulator und Mac: 0 Warnungen. String Catalog unverändert.
  - Beobachtung: 8 Tags brauchen auf dem iPhone 3 Zeilen, die Zeile wird gut doppelt so hoch. Ab etwa 20 Tags
    würde eine Zeile einen großen Teil des Bildschirms füllen. Gedeckelt wird bewusst nicht (Entscheid Christian).

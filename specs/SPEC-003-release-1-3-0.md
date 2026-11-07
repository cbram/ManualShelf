# SPEC-003 — ManualShelf 1.3.0: Vorschau, Dark-Mode-Icon, Download per URL, Titelvorschlag, Export

**Status:** In Arbeit (F1–F12 entschieden; #4 wartet auf Christians Icon-Dateien) · **Bau:** Kai · **Abnahme:** Christian
**Version:** 1.3.0 (neue Funktionen ⇒ Minor), Tag `v1.3.0` erst nach Christians Abnahme
**Umfang:** GitHub-Issues #3, #4, #8, #9, #13

## 1. Entscheide (Christian, 07.11.2026)

- **E1** 1.3.0 enthält alle offenen Issues außer #11 (Kaufdatum) und #12 (Rechnung/Garantie); die beiden entfallen.
- **E2** Auf GitHub wird nichts an den Issues geändert (kein Schließen, kein Kommentar); das klärt Fritz mit Christian.
- **E3** Neue Texte kommen in den String Catalog, englisch (Schlüssel) und deutsch (Du-Form), wie SPEC-002.

## 2. Issues und Ist-Stand (gemessen auf main `e00ffae`, `gh issue view`, nur lesend)

Alle fünf Issues haben **nur einen Titel**, keinen Beschreibungstext und keine Kommentare (angelegt 06.–08.06.2025,
Label `enhancement`). Die Deutung unten ist deshalb ein Vorschlag.

### #3 „Add preview in Manual View“

- **Ist:** Die Liste (`ManualRow`) zeigt je Manual nur ein SF-Symbol (PDF- oder Fotosymbol der ersten Datei). Die
  Detailansicht (`ManualDisplayView`) listet die Dateien mit Symbol und Dateiname; erst ein Tipp öffnet die Datei
  in `FileDisplayView` (PDFKit bzw. Bildansicht mit Zoom/Drehen) [HOCH, Code].
- **Keine** Vorschaubilder (Thumbnails) irgendwo im Code, kein Quick Look [HOCH, grep].

### #4 „Add dark mode icon“

- **Ist:** `AppIcon.appiconset` hat ein einziges Bild `ManualShelf.png` (1024 × 1024, ohne Alpha). Die Einträge
  für die Varianten „Dark“ und „Tinted“ sind im Asset schon angelegt, aber **leer** (kein Bild) [HOCH, Datei].
- Das Icon hat bereits einen dunklen Hintergrund (Bücher auf dunklem Grund).
- Dunkle und getönte App-Icons gibt es ab **iOS 18**; unter iOS 17 zeigt das System immer das Standard-Icon
  [MITTEL, Apple-HIG „App icons“, nicht live geprüft]. Mindest-OS 17.0 ist also kein Hindernis: iOS 17 ignoriert
  die Varianten, ab iOS 18 werden sie genutzt. Ab iOS 26 gibt es zusätzlich das Icon-Composer-Format (`.icon`,
  Liquid Glass) [MITTEL].

### #8 „Add new manuals by downloading via URL“

- **Ist:** Dateien kommen nur über `DocumentPickerView` (`UIDocumentPickerViewController`, Typen PDF/JPEG/PNG,
  Typprüfung über UTType bzw. Dateiendung, eine Datei pro Auswahl). Kein Netzwerkcode in der App außer CloudKit
  [HOCH, grep].
- Dateien liegen als `fileData` (Binary, **nicht** extern gespeichert) in Core Data und werden über CloudKit
  synchronisiert; ein Größenlimit gibt es heute auch beim Picker nicht [HOCH, Modell + Code].

### #9 „Suggest filename as title for new manual“

- **Ist:** In „Neues Manual“ ist der Titel ein leeres Pflichtfeld; der Dateiname wird nur in der Dateiliste
  angezeigt, nie als Titel übernommen [HOCH, Code].

### #13 „Enable exporting of files“

- **Ist:** Kein Teilen/Exportieren (`ShareLink`, `UIActivityViewController`, `fileExporter`: 0 Treffer). Die
  Dateien existieren nur als Daten in Core Data, nicht als Dateien auf der Platte [HOCH, grep].

## 3. Fragen F1–F12 (Owner-Entscheid Christian, 07.11.2026: alle nach Empfehlung; #4: Christian liefert die Icons)

### #3 Vorschau

- **F1 Deutung:** Vorschaubilder (Thumbnails) statt der Symbole: in der Liste das Vorschaubild der ersten Datei
  eines Manuals, in der Detailansicht je Datei ein Vorschaubild (PDF: erste Seite, Bild: verkleinert). Quick Look
  bringt keinen Mehrwert, weil die App schon einen eigenen Betrachter mit Drehen und Zoom hat. **Empfehlung:** so.
- **F2 Technik:** Vorschaubilder werden beim Anzeigen erzeugt (`QLThumbnailGenerator` bzw. PDFKit) und nur im
  Speicher gehalten, **ohne** Änderung am Datenmodell und ohne Sync-Last. Drehung (`pdfRotationDegrees`,
  `imageRotationDegrees`) wird im Vorschaubild berücksichtigt. **Empfehlung:** so; ein gespeicherter Cache wäre
  ein späterer Schritt, falls lange Listen spürbar ruckeln.

### #4 Dark-Mode-Icon

- **F3 Varianten:** „Dark“ und „Tinted“ im bestehenden Asset befüllen (wirken ab iOS 18). Kein Umstieg auf Icon
  Composer in 1.3.0. **Empfehlung:** so.
- **F4 Gestaltung:** Apple erwartet für „Dark“ das Motiv auf transparentem Grund und für „Tinted“ eine
  Graustufenfassung. Aus dem flachen 1024-PNG lässt sich das nur grob ableiten (Hintergrund wegmaskieren), das
  Ergebnis ist unsicher [NIEDRIG]. **Empfehlung:** Christian liefert die Quelldatei mit Ebenen oder die beiden
  fertigen PNGs; Plan B: ich leite sie ab und Christian beurteilt sie am Gerät.

### #8 Download per URL

- **F5 Protokoll und Weiterleitungen:** nur `https`. Weiterleitungen werden gefolgt, aber nur auf `https`-Ziele
  (App Transport Security blockt `http` ohnehin) [MITTEL]. **Empfehlung:** so, keine ATS-Ausnahme.
- **F6 Größenlimit:** 50 MB je Download; darüber Abbruch mit Meldung. Grund: die Daten liegen in der Datenbank
  und gehen über die iCloud-Synchronisation. Das Limit gilt nur für den Download, der Datei-Picker bleibt wie er
  ist. **Empfehlung:** 50 MB; das genaue CloudKit-Limit für große Dateien habe ich nicht geprüft [NIEDRIG].
- **F7 Dateitypen:** wie bisher nur PDF, JPEG, PNG. Erkannt am Dateiinhalt (Signatur `%PDF`, `FF D8 FF`,
  `89 50 4E 47`), nicht nur am `Content-Type` des Servers. Dateiname aus `Content-Disposition`, sonst aus dem
  letzten Teil der URL; fehlt die Endung, wird sie aus dem erkannten Typ ergänzt. **Empfehlung:** so.
- **F8 Fehlerfälle** mit eigener Meldung (EN/DE): ungültige oder nicht-`https`-URL, offline/Zeitüberschreitung
  (60 s), HTTP-Status außerhalb 200–299, zu groß, nicht unterstützter Dateityp, leere Antwort. Abbrechen während
  des Downloads möglich. **Empfehlung:** so.
- **F9 Ort in der App:** In „Neues Manual“ neben „Weitere Datei hinzufügen...“ ein zweiter Eintrag „Aus URL
  laden...“; in der Detailansicht wird der „+“-Knopf zu einem Menü mit „Datei auswählen“ und „Aus URL laden“.
  **Empfehlung:** beide Stellen.
- **F10 Datenschutz und Entitlements:** Beim Download ruft die App die vom Nutzer eingegebene Adresse direkt auf;
  dieser Server sieht dabei IP-Adresse und Anfrage, an den Entwickler geht weiterhin nichts. Ein Satz dazu kommt
  in `PrivacyPolicy.md`, `PrivacyPolicy.de.md` und die Datenschutz-Abschnitte der App-Store-Texte. Ein
  zusätzliches Netzwerk-Entitlement ist nicht nötig: iOS-Apps dürfen ins Netz, und „Designed for iPad“ auf dem
  Mac läuft mit den iOS-Rechten [MITTEL, nicht am Mac gemessen — wird beim Bau geprüft]. **Empfehlung:** so.

### #9 Titelvorschlag

- **F11 Regel:** Wird die **erste** Datei hinzugefügt (Picker oder URL) und ist das Titelfeld leer (nach Trimmen),
  wird der Dateiname **ohne Endung** als Titel eingesetzt, sonst nichts verändert (keine Umwandlung von `_`/`-`).
  Ein schon getippter Titel wird nie überschrieben; löscht man den Titel später, wird er nicht automatisch neu
  gefüllt. **Empfehlung:** so.

### #13 Export

- **F12 Umfang:** System-Teilen-Menü (`ShareLink`) reicht: in der Dateiansicht ein Teilen-Knopf für die
  angezeigte Datei, in der Detailansicht „Alle Dateien teilen“ für alle Dateien eines Manuals. Die Dateien werden
  dafür unter ihrem Originalnamen in den temporären Ordner geschrieben, damit der Empfänger (Dateien-App, Mail,
  AirDrop) den richtigen Namen sieht; gedreht wird beim Export nicht (Originaldatei). **Empfehlung:** so.

## 4. Aufwand (Schätzung)

| Issue | Aufwand | Konfidenz |
|---|---|---|
| #9 Titelvorschlag | 0,5–1 h | [HOCH] |
| #13 Export | 2–3 h | [MITTEL] |
| #3 Vorschaubilder | 3–5 h | [MITTEL] |
| #8 Download per URL inkl. Tests und Datenschutztexten | 4–6 h | [MITTEL] |
| #4 Icon-Varianten (Christian liefert / ich leite ab) | 0,5 h / 1–2 h | [HOCH] / [NIEDRIG] |
| Texte EN/DE, Tests, Abnahme | 1–2 h | [MITTEL] |
| **Summe** | **≈ 1,5–2 Arbeitstage** | [MITTEL] |

Reihenfolge im Bau: #9 → #13 → #3 → #8 → #4, je Issue ein Commit; danach `MARKETING_VERSION = 1.3.0`.

## 5. Abnahme

- Swift 6, Debug und Release, Simulator und Mac („Designed for iPad“): 0 Warnungen; Tests grün; Build ohne `+dirty`.
- `-exportLocalizations`: Deutsch vollständig.
- Unit-Tests für die reine Logik: Titelvorschlag (#9), Typ-Erkennung und Fehlerfälle des Downloads (#8, ohne echtes
  Netz), Dateinamen beim Export (#13).
- Gerätetest durch Christian mit höchstens 5 Punkten.

## 6. Verlauf

- 07.11.2026: E1–E3 von Christian; Messung und Spec (Kai, `c6c8b63`).
- 07.11.2026: F1–F12 von Christian nach Empfehlung entschieden; F4: Christian liefert die Icon-Dateien, Plan B
  (Ableitung durch Kai) nur auf seinen Wunsch. Bau #9 → #13 → #3 → #8 gestartet.
- 07.11.2026, Prüfungen vor #8:
  - **F6 iCloud-Limit:** nicht schnell belegbar. Apple-Doku nennt keine aktuelle Obergrenze je Asset; Foren
    widersprechen sich (Apple-Forum: bis ≈ 50 GB je Asset bei genug iCloud-Speicher, developer.apple.com/forums/thread/827897;
    ältere Referenz: 250 MB). Core Data legt zu große Werte selbst als Asset ab (developer.apple.com/forums/thread/651358).
    ⇒ 50 MB bleibt als Vorsichtsgrenze [NIEDRIG].
  - **F10 Netzwerk-Entitlement:** Christians signierter Mac-Build („Designed for iPad“, `Debug-iphoneos`) trägt nur die
    iOS-Entitlements (CloudKit, Push), kein `com.apple.security.network.client`; „Designed for iPad“ nutzt das
    iOS-Rechtemodell, ausgehende Verbindungen brauchen dort kein Entitlement [MITTEL]. Starten konnte ich die App auf
    dem Mac nicht (ohne Signatur nicht lauffähig) ⇒ Download am Mac ist Punkt im Gerätetest.

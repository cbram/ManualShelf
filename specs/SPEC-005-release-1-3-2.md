# SPEC-005 — ManualShelf 1.3.2: App-Store-Einreichung

**Status:** in Arbeit · **Vorbereitung:** Kai · **Handschritte + Freigabe:** Christian
**Version:** 1.3.2 (keine Funktionsänderung ⇒ Patch), Tag `v1.3.2` erst nach Christians Freigabe

## 1. Anlass und Umfang

ManualShelf ist laut Christian im App Store, vermutlich mit dem Stand von 1.0 (Juni 2025). Seitdem kamen 1.1.0 bis
1.3.1 dazu. 1.3.2 bringt diesen Stand in den Store und ändert **nichts an der Funktion**:

- `ITSAppUsesNonExemptEncryption = NO` in `ManualShelf/Info.plist`, damit App Store Connect nicht bei jedem Upload
  nach der Exportkonformität fragt. Die App nutzt nur Verschlüsselung des Systems (HTTPS, iCloud).
- Marketing-Version 1.3.2.
- Store-Texte in `AppStoreInfo.md` / `AppStoreInfo.de.md`: Beschreibung um die neuen Funktionen ergänzt,
  Werbetext und „Neu in dieser Version“ neu.
- Screenshots (nicht im Repo): `/Users/chbram/Code/ManualShelf/AppStoreScreenshots/1.3.2/`.

## 2. Datenmodell seit 1.0 (entscheidet über das CloudKit-Schema)

`git diff v1.0 HEAD -- ManualShelf/ManualShelf.xcdatamodeld`, nur eine Modellversion, ein einziger Commit:
`b2b35fc` (07.06.2025, „Barrierefreies Tag-Color-Coding …“), zuerst in `v1.1.0` [HOCH, git]:

- neue Entität `ManualTag` (`name`, `color`, Beziehung `manuals`)
- `ManualFile`: neues Attribut `imageRotationDegrees` (Integer 16), neue Beziehung `manualTags`
  (viele-zu-viele zu `ManualTag`)
- `ManualFile`: Codegen von „Class Definition“ auf manuell (ohne Wirkung auf CloudKit)

Seit `b2b35fc` keine Änderung mehr am Modell [HOCH, git log].

**Folge:** Läuft im Store wirklich 1.0, kennt das **Production**-Schema von CloudKit diese Felder vermutlich nicht.
Die Store-Version würde Tags und Bilddrehung dann nicht synchronisieren. Deshalb das Schema **vor** der Einreichung
nach Production bringen (§3 Schritt 1). Ob Christian es nach dem Juni 2025 schon einmal deployt hat, lässt sich
nur in der CloudKit Console sehen.

## 3. Handschritte Christian (Checkliste)

1. **CloudKit-Schema nach Production**
   - Öffne https://icloud.developer.apple.com → CloudKit Console → Container `iCloud.com.CHJB.ManualShelf`.
   - Kontrolle **Development**: Schema → Record Types muss `CD_ManualTag` (Felder `CD_name`, `CD_color`) und bei
     `CD_ManualFile` das Feld `CD_imageRotationDegrees` zeigen, dazu den Typ `CDMR` (so speichert Core Data
     viele-zu-viele-Beziehungen). Fehlt etwas: eine Development-Version aus Xcode starten, ein Manual mit Tag
     anlegen und ein Bild drehen, bis es synchronisiert ist.
   - Links unten „Deploy Schema Changes…“ wählen. Der Dialog listet, was Production fehlt. Steht dort nichts,
     war das Schema schon deployt → nichts zu tun. Sonst „Deploy“ bestätigen.
   - Production-Schema lässt sich nur ergänzen, nie zurücknehmen; die Änderung hier fügt nur hinzu.
2. [ ] **Freigabe** der Commits auf `main` → Fritz pusht und setzt Tag `v1.3.2`.
3. [ ] **Archiv aus sauberem Klon des Tags:**
   `git clone --branch v1.3.2 http://192.168.10.20:3333/admin/ManualShelf.git /tmp/ManualShelf-1.3.2`
   → Projekt in Xcode öffnen → Destination „Any iOS Device“ → Product › Archive. Im Organizer muss die Version
   `1.3.2 (<Commit-Anzahl> · <Hash von v1.3.2>)` ohne `+dirty` lauten → „Distribute App“ → „App Store Connect“ →
   Upload.
4. [ ] **App Store Connect:** App → „+“ neben iOS-App → Version `1.3.2` anlegen → nach der Verarbeitung den Build
   auswählen. Die Frage zur Exportkonformität darf nicht mehr kommen.
5. [ ] **Texte** je Sprache (Englisch = Grundsprache, Deutsch): Beschreibung, Werbetext, Keywords und
   „Neu in dieser Version“ aus `AppStoreInfo.md` / `AppStoreInfo.de.md` übernehmen. Fehlt die deutsche
   Lokalisierung im Store, rechts oben über die Sprachauswahl „Deutsch“ hinzufügen.
6. [ ] **Screenshots** aus `/Users/chbram/Code/ManualShelf/AppStoreScreenshots/1.3.2/` hochladen
   (Ordner `en/` bzw. `de/`, je Gerät; PNG ohne Alpha). Maße nach Apples „Screenshot specifications“
   (abgerufen 08.11.2026) [HOCH]:
   - `iPhone-6.9/` 1320 × 2868 → „iPhone 6,9"“ (große Anzeige mit Dynamic Island)
   - `iPhone-6.3/` 1206 × 2622 → „iPhone 6,3"“ (mittlere Anzeige). Apple nennt diese Größe als **Pflicht**
     für iPhone; ob App Store Connect sie aus 6,9" herunterskaliert, sagt die Seite nicht eindeutig ⇒ beide
     hochladen.
   - `iPad-13/` 2064 × 2752 → „iPad 13"“ (Pflicht, da die App iPad unterstützt)
   - Motive je Gerät: `01-list`, `02-detail`, `03-new-manual`. Aufgenommen mit `-uiTestSampleData`
     (Beispieldaten „Beispiel-Manual 0–4“, Dateien ohne Inhalt ⇒ **keine Vorschaubilder**, deutsche Titel
     auch in den englischen Bildern). Vor dem Hochladen ansehen; reichen sie nicht, eigene Aufnahmen vom
     Gerät mit echten Manuals nehmen.
7. [ ] **Datenschutzangaben (App-Datenschutz) prüfen:** Bisher „Keine Daten erfasst“. Das Laden per URL (neu
   in 1.3.0) ändert daran voraussichtlich nichts: Die App ruft die vom Nutzer eingegebene Adresse direkt auf,
   weder der Entwickler noch ein Partner erhält dabei Daten. Apple zählt als „Erfassen“ nur Daten, auf die der
   Entwickler oder seine Partner zugreifen können [MITTEL, Apple-Definition „collect“, nicht live geprüft].
   Datenschutzrichtlinie (Support-URL) nennt den direkten Abruf bereits.
8. [ ] **Altersfreigabe prüfen:** Apple hat den Fragebogen 2025 überarbeitet; offene Fragen müssen beantwortet
   sein, sonst blockiert die Einreichung. Neu relevant ist nur „Uneingeschränkter Webzugriff“: ManualShelf lädt
   einzelne PDF/JPEG/PNG-Dateien per Adresse, zeigt aber keine Webseiten. Kai empfiehlt „Nein“ [NIEDRIG,
   Abgrenzung von Apple nicht belegt] — Entscheid Christian.
9. [ ] **Einreichen** („Zur Prüfung hinzufügen“ → „An App-Review senden“), Veröffentlichung manuell oder
   automatisch nach Wahl.

## 4. Verlauf

- 08.11.2026: Kai bereitet vor (Commits auf `main`, nicht gepusht, kein Tag): Info.plist-Schlüssel,
  Version 1.3.2, Store-Texte, Screenshots, diese Spec.
- 08.11.2026: Tests auf iPhone 18 Pro Max (iOS 27.2, Simulator) grün: alle Unit-Tests, alle UI-Tests (UI-Tests im
  zweiten Anlauf; erster Anlauf brach mit Simulator-Zeitüberschreitungen ab, Rechner stark ausgelastet).
  Gebautes `Info.plist`: `ITSAppUsesNonExemptEncryption` = false, Version 1.3.2, `UIBackgroundModes` unverändert.
- Screenshots per temporärem UI-Test (nicht committet) aufgenommen, Statusleiste 9:41. Mängel: `iPhone-6.3/`
  zeigt links oben „◀ Plattenschrank“ (Rest im geteilten Simulator); `iPad-13/en/` zeigt das Datum in der
  Statusleiste deutsch; im iPad-Detailbild ist die ausgewählte Zeile blau, ihr Symbol darin unsichtbar.

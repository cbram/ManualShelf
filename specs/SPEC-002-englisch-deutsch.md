# SPEC-002 — ManualShelf 1.2.0: Englisch als Grundsprache, Deutsch als Übersetzung

**Status:** Spec, offene Fragen F1–F8 bei Christian · **Bau:** Kai · **Abnahme:** Christian
**Version:** 1.2.0 (neue Sprache ⇒ Minor), Tag `v1.2.0` erst nach Christians Abnahme
**Vorbild:** LyricSync SPEC-004 (`~/Code/LyricSync/specs/SPEC-004-englisch-deutsch.md`)

## 1. Ziel

ManualShelf soll auch anderen nützen (Entscheid Mindest-OS 07.11.2026). Die Oberfläche wird zweisprachig:
Englisch ist Grundsprache, Deutsch die Übersetzung. Die App folgt der Systemsprache bzw. der Sprache pro App
(iOS: Einstellungen › ManualShelf › Sprache; Mac: Systemeinstellungen › Allgemein › Sprache & Region › Apps).

## 2. Entscheide (Christian, 07.11.2026)

- **E1** Englisch = Entwicklungssprache (`developmentRegion = en`), Deutsch = Übersetzung. Vorgehen wie LyricSync
  SPEC-004: ein String Catalog (`Localizable.xcstrings`), keine fest im Code stehenden UI-Texte.
- **E2** Die deutsche Fassung duzt durchgehend (bisher teils „Wählen Sie …“, „Bitte geben Sie …“).
- **E3** Begleittexte auf Englisch und Deutsch: Datenschutzerklärung und App-Store-Text bekommen eine englische
  Fassung. Das README ist englisch (siehe F6: es ist heute deutsch).
- **E4** Version 1.2.0; Tag erst nach Christians Abnahme.

## 3. Messung (main `bb98d03`, 07.11.2026)

- **Projekt:** `developmentRegion = en` ist bereits gesetzt, `knownRegions = (en, Base)`. Es gibt noch keinen
  String Catalog und keine `.strings`-Datei. Alle UI-Texte sind deutsche Literale im Code [HOCH, grep].
- **Info.plist:** keine lokalisierbaren Schlüssel (keine Usage-Descriptions; Anzeigename „ManualShelf“ bleibt) ⇒
  kein `InfoPlist.xcstrings` nötig [HOCH].
- **≈ 61 eindeutige UI-Texte** in 9 Dateien [MITTEL, Handzählung aus grep; die genaue Zahl liefert der Bau über
  `xcodebuild -exportLocalizations`]:

| Datei | Texte | Art |
|---|---|---|
| `ManualDisplayView.swift` | ≈ 17 | `Text`, `TextField`, `Button`, `navigationTitle`, Alert-Titel/-Meldungen (`String`-Variablen), Fehleransicht, Seitenzähler „%lld von %lld“, VoiceOver „Tag %@ entfernen“ |
| `AddManualView.swift` | 14 | `Text`, `TextField`-Platzhalter, `Button`, `navigationTitle`, Alert-Titel/-Meldungen |
| `CloudKitSyncStatusView.swift` | 7 | Statustexte als `String`-Rückgabe, Kontextmenü, Datumszeile |
| `SettingsView.swift` | 6 | Abschnittsköpfe, Hinweistext, `LabeledContent`, `navigationTitle`, `Button` |
| `CloudKitSyncManager.swift` | 5 | Fehlertexte im Status (`.error(String)`) |
| `SortOption.swift` | 4 | `rawValue` dient als Anzeigetext |
| `FetchedManualsDisplayView.swift` | 4 | Leerzustand, Platzhaltertitel, Zeile „%lld Datei(en) – Hinzugefügt: %@“ |
| `DocumentPickerView.swift` | 3 | `errorDescription` |
| `ManualsListView.swift` | 3 | Suchfeld-Prompt, `Picker`, Platzhalter iPad |

- **Nicht übersetzt:** `print`-Logs (9), `fatalError`, Preview-Beispieldaten, SF-Symbol-Namen, `NSPredicate`,
  UserDefaults-/Info.plist-Schlüssel; `EditButton` übersetzt das System selbst.
- **Formatierung:** Beide `DateFormatter` nutzen das Gebietsschema (kein festes `de_DE`) ⇒ Datum/Zeit stimmen in
  beiden Sprachen ohne Änderung [HOCH, Code].
- **Schon heute englische Begriffe in der deutschen UI:** „Manual“, „Tags“, „Tag hinzufügen“.
- **Ohne VoiceOver-Label:** 11 reine Symbol-Knöpfe (Plus ×2, Sortieren, Einstellungen, ✕ ×2 in „Neues Manual“,
  Bild vor/zurück, Drehen links/rechts ×2) — VoiceOver liest dort den englischen Symbolnamen (siehe F4).
- **Code-Kommentare:** ≈ 193 Kommentarzeilen, überwiegend deutsch (siehe F7).

## 4. Umsetzung (Plan)

- SwiftUI-Literale (`Text`, `Button`, `TextField`, `navigationTitle`, `Picker`, `LabeledContent`) sind
  `LocalizedStringKey`; Texte aus Variablen, Modell und Diensten (Alerts, Status, Fehler, `SortOption`) über
  `String(localized:)`. Zusammengesetzte Texte sind **ein** Schlüssel mit Platzhaltern (`%@`, `%lld`), damit die
  Übersetzung die Wortstellung frei wählen kann. Zahlen mit Plural-Varianten im Catalog (F2).
- Reine Daten (Titel, Dateinamen, Tag-Namen) bleiben `verbatim`.
- `SortOption`: Anzeigetext über eine eigene lokalisierte Eigenschaft; `rawValue` wird nicht gespeichert (nur
  `@State`), Umbau also ohne Datenwirkung [HOCH, Code].
- Schlüssel = englischer Text (Muster LyricSync). Projekt: `knownRegions` um `de` ergänzen.
- Begleittexte: englische Fassungen neben den deutschen (F5).
- Tests: Prüfung über `xcodebuild -exportLocalizations` (jeder Schlüssel hat Deutsch, außer gleichlautenden
  Begriffen nach F1); ein Unit-Test für Plural und Platzhalter in beiden Sprachen.

## 5. Offene Fragen (mit Empfehlung)

- **F1 Begriffe:** „Manual“ und „Tags“ bleiben in beiden Sprachen (gängig, schon heute so in der deutschen UI).
  Ebenso „iCloud“. **Empfehlung:** ja. Alternative wäre „Anleitung“ im Deutschen.
- **F2 Mehrzahl:** „%lld Datei(en)“ wird zu echten Plural-Varianten („1 Datei“ / „3 Dateien“, „1 file“ /
  „3 files“). **Empfehlung:** ja; der deutsche Text weicht damit bewusst vom Bisherigen ab.
- **F3 Deutsche Wortwahl:** Außer der Du-Umstellung (E2) bleiben die deutschen Texte wortgleich, nur Offensichtliches
  wird glattgezogen: „Synchronisation Status“ → „Synchronisationsstatus“, „Account-Fehler“/„Kein iCloud-Account“ →
  „iCloud-Konto“ (wie im Hinweistext der Einstellungen), „z.B.“ → „z. B.“. **Empfehlung:** so.
- **F4 VoiceOver-Labels:** Die 11 Symbol-Knöpfe ohne Label bekommen in diesem Release Labels in beiden Sprachen
  (z. B. „Add manual“/„Manual hinzufügen“, „Rotate left“/„Nach links drehen“). **Empfehlung:** ja, gleicher
  Arbeitsgang, sonst liest VoiceOver im Deutschen englische Symbolnamen.
- **F5 Dateinamen der Begleittexte:** `Datenschutz.md` → `PrivacyPolicy.md` (EN) + `PrivacyPolicy.de.md` (DE);
  `AppStoreInfo_de.md` → `AppStoreInfo.md` (EN) + `AppStoreInfo.de.md` (DE). **Empfehlung:** so — ein Schema für
  beide. Achtung: Falls die alte Datei per URL verlinkt ist (z. B. als Datenschutz-URL in App Store Connect),
  bricht ein Umbenennen den Link ⇒ dann `Datenschutz.md` behalten und nur `PrivacyPolicy.md` dazulegen.
- **F6 README:** Das README ist heute **deutsch**, nicht englisch. **Empfehlung:** README auf Englisch übersetzen
  (öffentlich auf GitHub) und keine zweite deutsche Fassung pflegen (One Way, One Truth). Alternative:
  `README.de.md` zusätzlich.
- **F7 Code-Kommentare:** ≈ 193 Zeilen, überwiegend deutsch; die globale Regel verlangt englische Kommentare
  (LyricSync E5 hat das mit erledigt). **Empfehlung:** in diesem Release als eigener Commit ins Englische, ohne
  Codeänderung. Alternative: später.
- **F8 Preview-Beispieldaten** („Anleitung Kaffeemaschine“ usw.) bleiben deutsch (nur in Xcode-Previews sichtbar).
  **Empfehlung:** ja, unverändert.

## 6. Abnahme

- Swift 6, Debug und Release, Simulator und Mac („Designed for iPad“): 0 Warnungen; Tests grün; Build ohne `+dirty`.
- `xcodebuild -exportLocalizations`: jeder Schlüssel hat eine deutsche Übersetzung.
- Simulator-Durchlauf bzw. Screenshots in Englisch und Deutsch (Team); Gerätetest mit höchstens 5 Punkten
  (Christian).

## 7. Verlauf

- 07.11.2026: E1–E4 von Christian; Messung und Spec (Kai). Bau wartet auf F1–F8.

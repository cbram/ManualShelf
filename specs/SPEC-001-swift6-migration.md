# SPEC-001: Migration auf Swift 6 (Swift-6-Sprachmodus, strikte Concurrency)

**Datum:** 2026-11-07
**Owner-Freigabe:** [x] Bau beauftragt am 2026-11-07 (Christian: „offene Punkte in Ordnung bringen“) · [x] Entscheide E1–E6 bestätigt am 2026-11-07 · [ ] Abnahme bestanden
**Status:** Gebaut auf main, wartet auf Christians Gerätetest
**Owner:** Christian · **Build:** Kai · **Abnahme:** Christian
**Ziel-Version:** **1.1.0** (Versionsschema bereits auf main, Tag `v1.1.0` erst nach Christians Abnahme)
**Vorbild:** GPS-Track SPEC-004, PhotoCropper SPEC-004

---

## 1. Anlass

ManualShelf steht auf `SWIFT_VERSION = 5.0` ohne strikte Concurrency-Prüfung und ohne
Default-Actor-Isolation. Messung auf main `d5314c4` (Clean Build Debug `build-for-testing`,
iOS-Simulator, Xcode 27.2):

- Mit `SWIFT_STRICT_CONCURRENCY=complete`: 0 Fehler, **23 Concurrency-Warnungen**, davon
  - 21 in `CloudKitSyncManager.swift` (Captures von `self` in `@Sendable`-Closures der
    CloudKit- und GCD-Callbacks),
  - 1 in `AppSettings.swift` (`static let shared` eines nicht-Sendable-Typs),
  - 1 in `Persistence.swift` (globale Variable `NSMergeByPropertyObjectTrumpMergePolicy`).
- Im Swift-6-Modus bricht der Build mit Fehlern ab (`static let shared` in `AppSettings` und
  `CloudKitSyncManager`).
- Test-Code: keine Warnungen (nur Xcode-Vorlagen).

Ein echtes Datenrennen gibt es im App-Code nach Lesart des Codes nicht: Alle Schreibzugriffe auf
`@Published`-Properties laufen bereits über `DispatchQueue.main` [MITTEL, Code gelesen, nicht
mit TSan gemessen].

## 2. Ziel

- Alle Konfigurationen (Debug, Release) aller drei Targets bauen im **Swift-6-Sprachmodus**
  ohne Fehler und **ohne Warnungen**, für iOS-Simulator und Mac („Designed for iPad“).
- Das Verhalten der App bleibt unverändert, insbesondere die iCloud-Synchronisation
  (CloudKit-Container, Store-Optionen, Merge-Policy, Statusanzeige).

## 3. Entscheide (Vorschlag Kai, von Christian bestätigt am 2026-11-07)

- **E1 Keine Default-Actor-Isolation:** `SWIFT_DEFAULT_ACTOR_ISOLATION` wird nicht gesetzt
  (wie PhotoTV SPEC-001). Begründung: Nur zwei Typen brauchen eine Isolation; ein
  projektweiter MainActor-Default wäre ein größerer Eingriff ohne Nutzen.
- **E2 UI-Zustand auf dem MainActor:** `AppSettings` und `CloudKitSyncManager` werden
  `@MainActor`. Beide sind `ObservableObject`s, die nur von SwiftUI-Views benutzt werden, und
  schreiben ihre `@Published`-Properties schon heute nur auf dem Main-Thread.
  `PersistenceController.updateCloudKitContainerCellularAccess` wird `@MainActor`, weil sie
  `AppSettings` schreibt.
- **E3 Callbacks:** Die CloudKit-Callbacks behalten `DispatchQueue.main.async` als Sprung auf
  den Main-Thread (kein Umbau auf `async`/`await`, damit das Timing gleich bleibt). Die
  Remote-Change-Notification wird per `.receive(on: DispatchQueue.main)` auf den Main-Thread
  geholt, statt im `sink` selbst zu dispatchen — gleiches Timing (ein asynchroner Main-Hop),
  aber für den Compiler prüfbar.
- **E4 Merge-Policy:** `NSMergeByPropertyObjectTrumpMergePolicy` (globale Variable) wird durch
  `NSMergePolicy.mergeByPropertyObjectTrump` ersetzt — dieselbe Policy, Apples
  Swift-Schreibweise.
- **E5 Escape-Hatches:** Ziel ist keine (`nonisolated(unsafe)`, `@unchecked Sendable`,
  `@preconcurrency`, `MainActor.assumeIsolated`). Wird doch eine nötig, steht sie mit Begründung
  in §7.
- **E6 Abnahme:** siehe §6.

## 4. Scope

### 4.1 Drin

| # | Was | Wo | Phase |
|---|---|---|---|
| 1 | `@MainActor` für `AppSettings`, `CloudKitSyncManager`, `updateCloudKitContainerCellularAccess`; Remote-Change über `receive(on:)` (E2, E3) | AppSettings, CloudKitSyncManager, Persistence | 1 |
| 2 | Merge-Policy (E4) | Persistence | 1 |
| 3 | `SWIFT_VERSION = 6.0` in allen 6 Konfigurationen (3 Targets) | project.pbxproj | 2 |

### 4.2 Nicht drin

- `ObservableObject` wird nicht auf `@Observable` umgestellt.
- Kein Refactoring außerhalb der Concurrency-Pfade (Surgical Changes), auch nicht der
  Auffälligkeiten aus §8.
- Keine neuen Tests (die vorhandenen sind Xcode-Vorlagen); Abdeckung bleibt Christians
  Gerätetest.

## 5. Phasen

- **Phase 1 – Warnungen auf 0 im Swift-5-Modus**, gemessen mit
  `SWIFT_STRICT_CONCURRENCY=complete` als Kommandozeilen-Override. Ein Umbau = ein Commit.
- **Phase 2 – Umschalten** auf `SWIFT_VERSION = 6.0`, danach Abnahme nach §6.1.

## 6. Abnahmekriterien

### 6.1 Team

1. `SWIFT_VERSION = 6.0` in allen 6 Konfigurationen.
2. Debug und Release, iOS-Simulator und Mac („Designed for iPad“, unsigniert): **0 Fehler,
   0 Warnungen** ohne Overrides.
3. Unit- und UI-Tests grün (Simulator).
4. Escape-Hatches nach E5.

### 6.2 Christians Gerätetest

1. App auf iPhone/iPad und Mac bauen, Version in den Einstellungen prüfen
   (`1.1.0 (N · hash)`, ohne `+dirty`).
2. Einstellungen öffnen: Status „iCloud verfügbar“ (bzw. korrekter Fehlertext ohne iCloud),
   kein Mobilfunk-Schalter mehr, Hinweistext zur automatischen Synchronisation sichtbar.
3. Auf Gerät A ein Manual anlegen oder ändern, auf Gerät B mit offenen Einstellungen prüfen,
   dass es ankommt und die Statusanzeige kurz „Änderungen empfangen“ zeigt. Kein Absturz
   (Laufzeit-Isolationsprüfung).
4. Statusanzeige antippen bzw. Kontextmenü „Synchronisation erzwingen“: kein Absturz, Status
   bleibt „iCloud verfügbar“.

## 7. Escape-Hatches

Keine. Der Swift-6-Modus kommt ohne `nonisolated(unsafe)`, `@unchecked Sendable`,
`@preconcurrency` und `MainActor.assumeIsolated` aus.

## 8. Auffälligkeiten (bei der Bauzeit gefunden, Entscheid Christian siehe §10)

- Der Schalter „Mobilfunk-Synchronisation erlauben“ speichert nur die Einstellung;
  `updateCloudKitContainerCellularAccess` setzt keine CloudKit- oder Store-Option
  (`NSPersistentCloudKitContainerOptions` wird nirgends konfiguriert). Die Synchronisation läuft
  also unabhängig vom Schalter nach Systemvorgabe [HOCH, Code].
- Die Statusanzeige „Synchronisiert“ bedeutet nur „iCloud-Account verfügbar“; die
  „synchronisiert gerade“-Phase ist eine feste 2-s-Anzeige nach einer Remote-Change-Notification
  [HOCH, Code].

## 9. Verlauf

- 07.11.2026 – Messung auf `d5314c4`, Spec erstellt (Kai, `f0a58b7`).
- 07.11.2026 – **Phasen 1 und 2 gebaut** (Kai, direkt auf main, kein Tag).
  - **Phase 1:** Concurrency-Warnungen unter `complete`, Clean Build Debug
    `build-for-testing`, iOS-Simulator:

    | Stand | Warnungen | Commit |
    |---|---|---|
    | Ausgang | 23 | `d5314c4` |
    | nach Item 1 (MainActor, `receive(on:)`, Weak-Kopie) | 1 | `4d48955` |
    | nach Item 2 (Merge-Policy) | **0** | `4d77d07` |

  - Bau-Abweichung zu E3: Im Account-Status-Callback wird die schwache Referenz vor dem
    Main-Hop in eine Konstante kopiert (`let manager = self`), weil der Compiler die
    schwache Variable im verschachtelten `@Sendable`-Closure sonst als geteilten
    veränderlichen Zustand meldet. Der Main-Hop selbst bleibt `DispatchQueue.main.async`.
  - **Phase 2:** `SWIFT_VERSION = 6.0` in allen 6 Konfigurationen (`afaa899`). Clean Builds
    ohne Overrides, jeweils 0 Fehler und 0 Warnungen: Debug und Release für iOS-Simulator und
    Mac („Designed for iPad“, unsigniert). Tests auf dem iPhone-16-Simulator grün
    (1 Unit-Test, 3 UI-Tests, alles Xcode-Vorlagen).
  - Offen: Gerätetest §6.2.
- 07.11.2026 – Christian bestätigt E1–E6 und entscheidet zu §8 (siehe §10). Gebaut (Kai):
  Mobilfunk-Schalter entfernt (`3ac6007`), Statusanzeige ehrlich (`d40549b`), Datenschutz-,
  App-Store- und README-Text angepasst (`ce424b4`).

## 10. Nachtrag 1: Mobilfunk-Schalter und Statusanzeige (Christian, 2026-11-07)

- **N1 Mobilfunk-Schalter entfernt:** Toggle, `AppSettings` (samt `SyncPreference` und
  UserDefaults-Key `syncPreferenceValue`) und `updateCloudKitContainerCellularAccess` sind weg.
  Ein gespeicherter alter Key wird ignoriert, keine Migration. Die Einstellungen erklären
  stattdessen, dass bei angemeldetem iCloud-Konto automatisch synchronisiert wird und sich das
  in den Einstellungen des Geräts unter iCloud abschalten lässt.
- **N2 Statusanzeige ehrlich:** „Synchronisiert“ heißt jetzt „iCloud verfügbar“ (= Account
  verfügbar). Die drehende 2-s-Phase „Synchronisiert…“ ist ersetzt durch einen statischen
  Hinweis „Änderungen empfangen“, der nur nach einer `NSPersistentStoreRemoteChange`-
  Notification erscheint; deren Zeitpunkt ersetzt das bisherige „Letzte Sync“. Keine echten
  Sync-Events über `eventChangedNotification` (größere Variante, nicht gewählt).
- **N3 Manueller Sync-Knopf:** Er erzwingt keine Synchronisation (dafür gibt es keine API);
  er speichert nur ungesicherte Änderungen des View-Kontexts und prüft den Account erneut.
  Die vorgetäuschte „Synchronisiert…“-Phase ist entfernt, der Knopf selbst und seine
  Beschriftung „Synchronisation erzwingen“ bleiben bis zu Christians Entscheid.
- **N4 Texte:** Datenschutz, App-Store-Text und README beschreiben die automatische
  Synchronisation über die private iCloud-Datenbank, ohne In-App-Schalter und ohne eigene
  Verschlüsselungszusage.

## 11. Nachtrag 2: Datenschutz, Sync-Knopf, Farben, Lizenz (Christian, 2026-11-07)

- **N5 Datenschutz:** Apple/iCloud wird als Speicherort genannt (private iCloud-Datenbank, Apples
  Datenschutzbestimmungen); der Entwickler erhebt nichts und hat keinen Zugriff. Gestrichen:
  „DSGVO nicht relevant“, „keine externen Dienste“, „keine Übertragung an Dritte“. Keine
  Analyse, kein Tracking, keine Werbung (per grep belegt: nur Apple-Frameworks, kein
  Netzwerkcode außer CloudKit). Lücke: kein Verantwortlicher mit Anschrift, nur die
  Support-URL — Christian entscheidet.
- **N6 Sync-Knopf entfernt:** Tippen auf die Statuszeile und „Synchronisation erzwingen“ samt
  `forceSynchronization()`. Der Account wird weiter beim Start des Managers, bei jedem
  Anzeigen der Statuszeile und über „Status prüfen“ geprüft (nicht beim Wechsel in den
  Vordergrund).
- **N7 Statusfarben Okabe-Ito:** verfügbar `#0072B2`, Fehler `#D55E00`, Änderungen empfangen
  `#CC79A7`, unbekannt Systemgrau; alle ≥ 3:1 auf hellen und dunklen Zeilen. Himmelblau
  `#56B4E9` verworfen (≈ 2,3:1 auf Weiß).
- **N8 Lizenz:** `LICENSE` (MIT, Copyright (c) 2025 Christian Bram), README-Verweis passt.

## 12. Nachtrag 3: stabile Tag-Farben (Christian, 2026-11-07)

- **Befund:** Liste (`FetchedManualsDisplayView`) und Detailansicht (`ManualDisplayView`) hatten
  je eine eigene Palette und wählten die Farbe über `String.hashValue`, der pro Prozess neu
  gesetzt wird ⇒ Farben wechselten bei jedem Start und zwischen den Ansichten; die Liste
  verschob Farben zusätzlich je Zeile. In der Detailansicht war der Text immer weiß (auf Gelb
  ≈ 1,3:1).
- **N9 Fix:** eine gemeinsame `TagColor.forName(_:)`: Name getrimmt und kleingeschrieben (wie
  der Tag-Abgleich der App), 64-bit FNV-1a über die UTF-8-Bytes, Index in 7 Okabe-Ito-Farben
  ohne Schwarz. Textfarbe je Hintergrund ≥ 4,5:1: Blau `#0072B2` weiß 5,2:1; Orange `#E69F00`
  9,3:1, Himmelblau `#56B4E9` 9,1:1, Blaugrün `#009E73` 6,1:1, Zinnober `#D55E00` 5,4:1,
  Rötliches Purpur `#CC79A7` 6,9:1, Gelb `#F0E442` 15,9:1 jeweils schwarz. Die
  Pro-Zeile-Eindeutigkeit entfällt bewusst (gleicher Name ⇒ gleiche Farbe überall; zwei Tags
  einer Zeile können dieselbe Farbe haben). `ManualTag.color` bleibt unbenutzt, keine Migration.
- **Tests:** `TagColorTests` mit fester Zuordnung (Wohnmobil 0, Garten 1, Werkzeug 3, Küche 4)
  und Gleichheit trotz Groß-/Kleinschreibung und Leerzeichen; mit `hashValue` statt FNV-1a
  schlagen 3 der 4 festen Zuordnungen fehl (gemessen).

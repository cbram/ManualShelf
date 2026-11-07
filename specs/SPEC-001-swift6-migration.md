# SPEC-001: Migration auf Swift 6 (Swift-6-Sprachmodus, strikte Concurrency)

**Datum:** 2026-11-07
**Owner-Freigabe:** [x] Bau beauftragt am 2026-11-07 (Christian: „offene Punkte in Ordnung bringen“) · [ ] Entscheide E1–E6 bestätigt · [ ] Abnahme bestanden
**Status:** Gebaut auf main, wartet auf Christians Bestätigung E1–E6 und Gerätetest
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

## 3. Entscheide (Vorschlag Kai, Bestätigung durch Christian offen)

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
2. Einstellungen öffnen: Status „Synchronisiert“ (bzw. korrekter Fehlertext ohne iCloud),
   Mobilfunk-Schalter umlegen, App neu starten — Schalterstellung bleibt erhalten.
3. Auf Gerät A ein Manual anlegen oder ändern, auf Gerät B prüfen, dass es ankommt und die
   Statusanzeige kurz „synchronisiert gerade“ zeigt. Kein Absturz (Laufzeit-Isolationsprüfung).
4. Manuellen Sync-Knopf in der Statusanzeige drücken.

## 7. Escape-Hatches

Keine. Der Swift-6-Modus kommt ohne `nonisolated(unsafe)`, `@unchecked Sendable`,
`@preconcurrency` und `MainActor.assumeIsolated` aus.

## 8. Auffälligkeiten (nicht Teil dieser Spec, Entscheid Christian)

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
  - Offen: Bestätigung E1–E6 durch Christian, Gerätetest §6.2.

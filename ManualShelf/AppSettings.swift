import Foundation

// Synchronisations-Präferenz für CloudKit
enum SyncPreference: Int, CaseIterable, Identifiable {
    case wifiOnly = 0
    case wifiAndCellular = 1

    var id: Int { self.rawValue }

    // Beschreibung für die UI
    var description: String {
        switch self {
        case .wifiOnly:
            return "Nur über WLAN"
        case .wifiAndCellular:
            return "WLAN und Mobilfunk"
        }
    }
}

class AppSettings: ObservableObject {
    // Singleton-Instanz für globale Einstellungen
    static let shared = AppSettings()
    private let syncPreferenceKey = "syncPreferenceValue"

    // Aktuelle Sync-Präferenz, wird in UserDefaults gespeichert
    @Published var syncPreference: SyncPreference {
        didSet {
            // Verhindert eine Endlosschleife, falls der Wert erneut auf denselben Wert gesetzt wird.
            guard oldValue != syncPreference else { return }
            
            UserDefaults.standard.set(syncPreference.rawValue, forKey: syncPreferenceKey)
            PersistenceController.shared.updateCloudKitContainerCellularAccess(allowed: syncPreference == .wifiAndCellular)
        }
    }

    // Initialisiert die Einstellungen und lädt gespeicherte Werte
    private init() {
        let storedValue = UserDefaults.standard.integer(forKey: syncPreferenceKey)
        self.syncPreference = SyncPreference(rawValue: storedValue) ?? .wifiOnly
    }
} 
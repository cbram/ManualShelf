import Foundation

enum SyncPreference: Int, CaseIterable, Identifiable {
    case wifiOnly = 0
    case wifiAndCellular = 1

    var id: Int { self.rawValue }

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
    static let shared = AppSettings()
    private let syncPreferenceKey = "syncPreferenceValue" // Geändert von "syncOverCellularAllowed"

    @Published var syncPreference: SyncPreference {
        didSet {
            UserDefaults.standard.set(syncPreference.rawValue, forKey: syncPreferenceKey)
            // CloudKit Container darüber informieren
            PersistenceController.shared.updateCloudKitContainerCellularAccess(allowed: syncPreference == .wifiAndCellular)

        }
    }

    private init() {
        let storedValue = UserDefaults.standard.integer(forKey: syncPreferenceKey)
        self.syncPreference = SyncPreference(rawValue: storedValue) ?? .wifiOnly // Default ist wifiOnly
    }
} 
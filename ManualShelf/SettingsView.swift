import SwiftUI
import CoreTelephony

struct SettingsView: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject private var appSettings = AppSettings.shared
    @State private var allowCellularSync: Bool

    // Initializer, um allowCellularSync basierend auf AppSettings zu setzen
    init() {
        _allowCellularSync = State(initialValue: AppSettings.shared.syncPreference == .wifiAndCellular)
    }

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("iCloud Synchronisation")) {
                    Toggle("Mobilfunk-Synchronisation erlauben", isOn: $allowCellularSync)
                        .onChange(of: allowCellularSync) { newValue in
                            appSettings.syncPreference = newValue ? .wifiAndCellular : .wifiOnly
                            // Rufe die Methode im PersistenceController auf, um die Änderung ggf. weiterzuverarbeiten
                            // Diese Methode aktualisiert intern AppSettings und gibt eine Log-Meldung aus.
                            PersistenceController.shared.updateCloudKitContainerCellularAccess(allowed: newValue)
                        }
                        .disabled(!isCellularAvailable())
                    Text("Wenn aktiviert, werden Daten auch über Mobilfunk synchronisiert. Andernfalls nur über WLAN. Änderungen werden beim nächsten App-Start oder bei der nächsten Synchronisierungsprüfung wirksam.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Section(header: Text("Synchronisation Status")) {
                    CloudKitSyncStatusView()
                }
                
                // Hier könnten zukünftig weitere Einstellungen hinzugefügt werden
                Section(header: Text("App-Informationen")) {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text(Bundle.main.appVersion ?? "N/A")
                    }
                }
            }
            .navigationTitle("Einstellungen")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Fertig") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
            // Stelle sicher, dass allowCellularSync aktualisiert wird, wenn sich die zugrundeliegende Einstellung ändert (z.B. durch andere Programmteile)
            .onReceive(appSettings.$syncPreference) { newPreference in
                allowCellularSync = (newPreference == .wifiAndCellular)
            }
        }
    }
    
    // Prüft, ob das Gerät Mobilfunk unterstützt
    private func isCellularAvailable() -> Bool {
        let networkInfo = CTTelephonyNetworkInfo()
        if let carrier = networkInfo.serviceSubscriberCellularProviders?.first?.value {
            // Wenn ein Carrier-Name vorhanden ist, gehen wir von Mobilfunkfähigkeit aus.
            // Dies ist eine Vereinfachung. Auf einem iPad ohne SIM aber mit eSIM-Fähigkeit
            // könnte dies ungenau sein, aber für die meisten Fälle ausreichend.
            return carrier.carrierName != nil
        }
        // Fallback für Geräte, die die Info anders bereitstellen
        #if os(iOS)
        return networkInfo.dataServiceIdentifier != nil
        #else
        return false // macOS, watchOS, etc. haben kein 'Mobilfunk' in diesem Sinne
        #endif
    }
}

// Kleine Erweiterung für Bundle, um die App-Version einfach abzurufen
extension Bundle {
    var appVersion: String? {
        self.infoDictionary?["CFBundleShortVersionString"] as? String
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
} 
import SwiftUI

struct SettingsView: View {
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Synchronisation Status")) {
                    CloudKitSyncStatusView()
                    Text("Ist auf dem Gerät ein iCloud-Konto angemeldet, synchronisiert ManualShelf automatisch über deine private iCloud-Datenbank. Abschalten lässt sich das in den Einstellungen des Geräts unter iCloud.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                // Hier könnten zukünftig weitere Einstellungen hinzugefügt werden
                Section(header: Text("App-Informationen")) {
                    LabeledContent("Version", value: Self.appVersionString)
                        .monospacedDigit()
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
        }
    }
    
    /// Version, build number and commit from the bundle, e.g. "1.1.0 (147 · b275e0f)".
    /// Build number and commit are stamped into Info.plist by Scripts/stamp-build-version.sh.
    private static var appVersionString: String {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "?"
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "0"
        let commit = Bundle.main.object(forInfoDictionaryKey: "GitCommit") as? String ?? "unknown"
        return "\(version) (\(build) · \(commit))"
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
} 
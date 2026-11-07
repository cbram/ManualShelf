//
//  CloudKitSyncStatusView.swift
//  ManualShelf
//
//  Created by Assistant on 02.06.25.
//

import SwiftUI
import CloudKit

struct CloudKitSyncStatusView: View {
    @StateObject private var syncManager = CloudKitSyncManager.shared
    
    var body: some View {
        HStack {
            // Status-Icon mit Animation je nach Sync-Status
            Image(systemName: iconName)
                .foregroundColor(iconColor)
            
            // Textuelle Statusbeschreibung
            Text(statusDescription)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        // Kontextmenü für weitere Sync-Aktionen
        .contextMenu {
            Button("Status prüfen") {
                syncManager.checkAccountStatus()
            }
            
            if let lastChange = syncManager.lastRemoteChangeDate {
                Text("Zuletzt Änderungen empfangen: \(lastChange, formatter: timeFormatter)")
            }
        }
        .onAppear {
            // Status beim Anzeigen prüfen
            syncManager.checkAccountStatus()
        }
    }
    
    // Liefert das passende Symbol für den aktuellen Sync-Status
    private var iconName: String {
        switch syncManager.syncStatus {
        case .unknown:
            return "questionmark.circle"
        case .changesReceived:
            return "arrow.down.circle.fill"
        case .accountAvailable:
            return "icloud.fill"
        case .error:
            return "exclamationmark.triangle.fill"
        }
    }
    
    // Liefert die passende Farbe für das Status-Icon
    private var iconColor: Color {
        switch syncManager.syncStatus {
        case .unknown:
            return Color(.systemGray)
        case .changesReceived:
            return Self.okabeItoReddishPurple
        case .accountAvailable:
            return Self.okabeItoBlue
        case .error:
            return Self.okabeItoVermillion
        }
    }

    // Okabe-Ito palette (colour-blind safe). Each reaches at least 3:1 against both the
    // light and the dark grouped row background. Sky blue (#56B4E9) was not used for
    // "changes received" because it only reaches about 2.3:1 on white.
    private static let okabeItoBlue = Color(red: 0x00 / 255, green: 0x72 / 255, blue: 0xB2 / 255)          // #0072B2
    private static let okabeItoVermillion = Color(red: 0xD5 / 255, green: 0x5E / 255, blue: 0x00 / 255)    // #D55E00
    private static let okabeItoReddishPurple = Color(red: 0xCC / 255, green: 0x79 / 255, blue: 0xA7 / 255) // #CC79A7
    
    // Liefert die textuelle Beschreibung des Sync-Status
    private var statusDescription: String {
        switch syncManager.syncStatus {
        case .unknown:
            return "Status unbekannt"
        case .changesReceived:
            return "Änderungen empfangen"
        case .accountAvailable:
            if let lastChange = syncManager.lastRemoteChangeDate {
                let formatter = RelativeDateTimeFormatter()
                formatter.unitsStyle = .short
                return "iCloud verfügbar · Änderungen empfangen \(formatter.localizedString(for: lastChange, relativeTo: Date()))"
            } else {
                return "iCloud verfügbar"
            }
        case .error(let message):
            return "Fehler: \(message)"
        }
    }
}

// Formatter für die Anzeige der letzten Synchronisation
private let timeFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.timeStyle = .short
    formatter.dateStyle = .none
    return formatter
}()

// Vorschau für SwiftUI Previews
#Preview {
    CloudKitSyncStatusView()
} 
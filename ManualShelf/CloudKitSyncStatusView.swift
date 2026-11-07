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
        // Tippen erzwingt eine Synchronisation
        .onTapGesture {
            syncManager.forceSynchronization()
        }
        // Kontextmenü für weitere Sync-Aktionen
        .contextMenu {
            Button("Synchronisation erzwingen") {
                syncManager.forceSynchronization()
            }
            
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
            return .gray
        case .changesReceived:
            return .blue
        case .accountAvailable:
            return .green
        case .error:
            return .red
        }
    }
    
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
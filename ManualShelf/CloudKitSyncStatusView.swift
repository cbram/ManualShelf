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
    @State private var shouldAnimateSyncIcon = false
    
    var body: some View {
        HStack {
            // Status-Icon mit Animation je nach Sync-Status
            Image(systemName: iconName)
                .foregroundColor(iconColor)
                .rotationEffect(shouldAnimateSyncIcon ? .degrees(359) : .degrees(0))
                .animation(shouldAnimateSyncIcon ? Animation.linear(duration: 1).repeatForever(autoreverses: false) : .default, value: shouldAnimateSyncIcon)
            
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
            
            if let lastSync = syncManager.lastSyncDate {
                Text("Letzte Sync: \(lastSync, formatter: timeFormatter)")
            }
        }
        .onAppear {
            // Status beim Anzeigen prüfen
            syncManager.checkAccountStatus()
            updateAnimationState(for: syncManager.syncStatus)
        }
        .onChange(of: syncManager.syncStatus) { newStatus in
            updateAnimationState(for: newStatus)
        }
    }
    
    // Startet oder stoppt die Icon-Animation je nach Sync-Status
    private func updateAnimationState(for status: CloudKitSyncManager.SyncStatus) {
        if status == .syncing {
            DispatchQueue.main.async {
                self.shouldAnimateSyncIcon = true
            }
        } else {
            self.shouldAnimateSyncIcon = false
        }
    }
    
    // Liefert das passende Symbol für den aktuellen Sync-Status
    private var iconName: String {
        switch syncManager.syncStatus {
        case .unknown:
            return "questionmark.circle"
        case .syncing:
            return "arrow.triangle.2.circlepath"
        case .synced:
            return "checkmark.circle.fill"
        case .error:
            return "exclamationmark.triangle.fill"
        }
    }
    
    // Liefert die passende Farbe für das Status-Icon
    private var iconColor: Color {
        switch syncManager.syncStatus {
        case .unknown:
            return .gray
        case .syncing:
            return .blue
        case .synced:
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
        case .syncing:
            return "Synchronisiert..."
        case .synced:
            if let lastSync = syncManager.lastSyncDate {
                let formatter = RelativeDateTimeFormatter()
                formatter.unitsStyle = .short
                return "Sync: \(formatter.localizedString(for: lastSync, relativeTo: Date()))"
            } else {
                return "Synchronisiert"
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
//
//  CloudKitSyncStatusView.swift
//  ManualShelf
//
//  Created by Assistant on 02.06.25.
//

import SwiftUI
import CloudKit // Wieder aktiviert

struct CloudKitSyncStatusView: View {
    @StateObject private var syncManager = CloudKitSyncManager.shared
    @State private var shouldAnimateSyncIcon = false
    
    var body: some View {
        HStack {
            Image(systemName: iconName)
                .foregroundColor(iconColor)
                .rotationEffect(shouldAnimateSyncIcon ? .degrees(359) : .degrees(0))
                .animation(shouldAnimateSyncIcon ? Animation.linear(duration: 1).repeatForever(autoreverses: false) : .default, value: shouldAnimateSyncIcon)
            
            Text(statusDescription)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .onTapGesture {
            // Manueller Sync bei Tap
            syncManager.forceSynchronization()
        }
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
            syncManager.checkAccountStatus()
            updateAnimationState(for: syncManager.syncStatus)
        }
        .onChange(of: syncManager.syncStatus) { newStatus in
            updateAnimationState(for: newStatus)
        }
    }
    
    private func updateAnimationState(for status: CloudKitSyncManager.SyncStatus) {
        if status == .syncing {
            DispatchQueue.main.async {
                self.shouldAnimateSyncIcon = true
            }
        } else {
            self.shouldAnimateSyncIcon = false
        }
    }
    
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

private let timeFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.timeStyle = .short
    formatter.dateStyle = .none
    return formatter
}()

#Preview {
    CloudKitSyncStatusView()
} 
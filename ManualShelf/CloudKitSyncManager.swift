//
//  CloudKitSyncManager.swift
//  ManualShelf
//
//  Created by Assistant on 02.06.25.
//

import Foundation
import CloudKit
import CoreData
import Combine

@MainActor
class CloudKitSyncManager: ObservableObject {
    // Singleton-Instanz für die App
    static let shared = CloudKitSyncManager()
    
    @Published var syncStatus: SyncStatus = .unknown
    @Published var lastSyncDate: Date?
    
    private let container = CKContainer.default()
    private var cancellables = Set<AnyCancellable>()
    
    // Repräsentiert den aktuellen Synchronisationsstatus
    enum SyncStatus: Equatable {
        case unknown
        case syncing
        case synced
        case error(String)
        
        static func == (lhs: CloudKitSyncManager.SyncStatus, rhs: CloudKitSyncManager.SyncStatus) -> Bool {
            switch (lhs, rhs) {
            case (.unknown, .unknown):
                return true
            case (.syncing, .syncing):
                return true
            case (.synced, .synced):
                return true
            case (.error(let lError), .error(let rError)):
                return lError == rError
            default:
                return false
            }
        }
    }
    
    private init() {
        setupRemoteChangeNotifications()
        checkAccountStatus()
    }
    
    // MARK: - Account Status
    // Prüft den iCloud-Account-Status und aktualisiert den Sync-Status entsprechend
    func checkAccountStatus() {
        container.accountStatus { [weak self] status, error in
            // Copy the weak reference into a constant so the main-queue closure
            // does not capture the mutable weak variable across threads.
            let manager = self
            DispatchQueue.main.async {
                if let error = error {
                    manager?.syncStatus = .error("Account-Fehler: \(error.localizedDescription)")
                    return
                }
                
                switch status {
                case .available:
                    manager?.syncStatus = .synced
                    manager?.lastSyncDate = Date()
                case .noAccount:
                    manager?.syncStatus = .error("Kein iCloud-Account")
                case .restricted:
                    manager?.syncStatus = .error("iCloud eingeschränkt")
                case .couldNotDetermine:
                    manager?.syncStatus = .error("Status nicht ermittelbar")
                case .temporarilyUnavailable:
                    manager?.syncStatus = .error("Temporär nicht verfügbar")
                @unknown default:
                    manager?.syncStatus = .unknown
                }
            }
        }
    }
    
    // MARK: - Remote Change Notifications
    // Reagiert auf Änderungen, die von anderen Geräten via CloudKit kommen
    private func setupRemoteChangeNotifications() {
        // The notification is posted on a background thread; deliver it on main.
        NotificationCenter.default.publisher(for: .NSPersistentStoreRemoteChange)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.syncStatus = .syncing
                // Simuliert eine kurze Sync-Phase
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    self?.syncStatus = .synced
                    self?.lastSyncDate = Date()
                }
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Manual Sync Trigger
    // Löst eine manuelle Synchronisation aus und speichert ggf. Änderungen
    func forceSynchronization() {
        syncStatus = .syncing
        
        let context = PersistenceController.shared.container.viewContext
        
        if context.hasChanges {
            do {
                try context.save()
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    self.syncStatus = .synced
                    self.lastSyncDate = Date()
                }
            } catch {
                syncStatus = .error("Sync-Fehler: \(error.localizedDescription)")
            }
        } else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                self.checkAccountStatus()
            }
        }
    }
    
    // MARK: - Conflict Resolution
    // Hinweis: CloudKit übernimmt die Konfliktbehandlung automatisch
    func handleSyncConflicts() {
        // CloudKit übernimmt automatisch die Konfliktbehandlung für Core Data.
        print("Konfliktbehandlung wird von CloudKit automatisch durchgeführt")
    }
    
    // MARK: - Debugging Helpers
    // Gibt CloudKit-Informationen für Debugging-Zwecke aus
    func printCloudKitInfo() {
        print("CloudKit Container ID: \(container.containerIdentifier ?? "unknown")")
        
        container.accountStatus { status, error in
            print("Account Status: \(status)")
            if let error = error {
                print("Account Error: \(error)")
            }
        }
    }
} 
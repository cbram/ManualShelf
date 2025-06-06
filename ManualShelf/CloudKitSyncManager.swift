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
            DispatchQueue.main.async {
                if let error = error {
                    self?.syncStatus = .error("Account-Fehler: \(error.localizedDescription)")
                    return
                }
                
                switch status {
                case .available:
                    self?.syncStatus = .synced
                    self?.lastSyncDate = Date()
                case .noAccount:
                    self?.syncStatus = .error("Kein iCloud-Account")
                case .restricted:
                    self?.syncStatus = .error("iCloud eingeschränkt")
                case .couldNotDetermine:
                    self?.syncStatus = .error("Status nicht ermittelbar")
                case .temporarilyUnavailable:
                    self?.syncStatus = .error("Temporär nicht verfügbar")
                @unknown default:
                    self?.syncStatus = .unknown
                }
            }
        }
    }
    
    // MARK: - Remote Change Notifications
    // Reagiert auf Änderungen, die von anderen Geräten via CloudKit kommen
    private func setupRemoteChangeNotifications() {
        NotificationCenter.default.publisher(for: .NSPersistentStoreRemoteChange)
            .sink { [weak self] notification in
                DispatchQueue.main.async {
                    self?.syncStatus = .syncing
                    // Simuliert eine kurze Sync-Phase
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        self?.syncStatus = .synced
                        self?.lastSyncDate = Date()
                    }
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
    
    // MARK: - CloudKit Operations
    // Fordert Berechtigungen für CloudKit an
    func requestCloudKitPermissions() {
        container.requestApplicationPermission(.userDiscoverability) { [weak self] status, error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.syncStatus = .error("Berechtigung verweigert: \(error.localizedDescription)")
                } else if status == .granted {
                    self?.checkAccountStatus()
                }
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
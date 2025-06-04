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
    static let shared = CloudKitSyncManager()
    
    @Published var syncStatus: SyncStatus = .unknown
    @Published var lastSyncDate: Date?
    
    private let container = CKContainer.default()
    private var cancellables = Set<AnyCancellable>()
    
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
    
    private func setupRemoteChangeNotifications() {
        // Lauscht auf Remote-Änderungen von CloudKit
        NotificationCenter.default.publisher(for: .NSPersistentStoreRemoteChange)
            .sink { [weak self] notification in
                DispatchQueue.main.async {
                    self?.syncStatus = .syncing
                    // Hier könnten Sie zusätzliche Logik für die Behandlung von Remote-Änderungen hinzufügen
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        self?.syncStatus = .synced
                        self?.lastSyncDate = Date()
                    }
                }
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Manual Sync Trigger
    
    func forceSynchronization() {
        syncStatus = .syncing
        
        // Core Data mit CloudKit synchronisieren
        let context = PersistenceController.shared.container.viewContext
        
        // Speichere alle ausstehenden Änderungen
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
            // Keine lokalen Änderungen, nur Status aktualisieren
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                self.checkAccountStatus()
            }
        }
    }
    
    // MARK: - CloudKit Operations
    
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
    
    func handleSyncConflicts() {
        // CloudKit übernimmt automatisch die Konfliktbehandlung für Core Data
        // Diese Methode kann für benutzerdefinierte Konfliktbehandlung erweitert werden
        print("Konfliktbehandlung wird von CloudKit automatisch durchgeführt")
    }
    
    // MARK: - Debugging Helpers
    
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
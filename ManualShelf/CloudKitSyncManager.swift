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
    // Time of the last store change that arrived via CloudKit, not of a completed sync
    @Published var lastRemoteChangeDate: Date?
    
    private let container = CKContainer.default()
    private var cancellables = Set<AnyCancellable>()
    
    // Repräsentiert den aktuellen Synchronisationsstatus.
    // The app cannot observe sync progress; it only knows whether the iCloud account
    // is available and when a remote change has reached the local store.
    enum SyncStatus: Equatable {
        case unknown
        case changesReceived
        case accountAvailable
        case error(String)
        
        static func == (lhs: CloudKitSyncManager.SyncStatus, rhs: CloudKitSyncManager.SyncStatus) -> Bool {
            switch (lhs, rhs) {
            case (.unknown, .unknown):
                return true
            case (.changesReceived, .changesReceived):
                return true
            case (.accountAvailable, .accountAvailable):
                return true
            case (.error(let lError), .error(let rError)):
                return lError == rError
            default:
                return false
            }
        }
    }
    
    private static let changesReceivedDisplayDuration: TimeInterval = 2

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
                    manager?.syncStatus = .accountAvailable
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
                self?.syncStatus = .changesReceived
                self?.lastRemoteChangeDate = Date()
                // Show the hint briefly, then return to the account state
                DispatchQueue.main.asyncAfter(deadline: .now() + Self.changesReceivedDisplayDuration) {
                    self?.syncStatus = .accountAvailable
                }
            }
            .store(in: &cancellables)
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
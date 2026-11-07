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
    // Shared instance for the app
    static let shared = CloudKitSyncManager()
    
    @Published var syncStatus: SyncStatus = .unknown
    // Time of the last store change that arrived via CloudKit, not of a completed sync
    @Published var lastRemoteChangeDate: Date?
    
    private let container = CKContainer.default()
    private var cancellables = Set<AnyCancellable>()
    
    // Current sync status.
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
    // Checks the iCloud account status and updates the sync status accordingly
    func checkAccountStatus() {
        container.accountStatus { [weak self] status, error in
            // Copy the weak reference into a constant so the main-queue closure
            // does not capture the mutable weak variable across threads.
            let manager = self
            DispatchQueue.main.async {
                if let error = error {
                    manager?.syncStatus = .error(String(localized: "Account error: \(error.localizedDescription)"))
                    return
                }
                
                switch status {
                case .available:
                    manager?.syncStatus = .accountAvailable
                case .noAccount:
                    manager?.syncStatus = .error(String(localized: "No iCloud account"))
                case .restricted:
                    manager?.syncStatus = .error(String(localized: "iCloud restricted"))
                case .couldNotDetermine:
                    manager?.syncStatus = .error(String(localized: "Status could not be determined"))
                case .temporarilyUnavailable:
                    manager?.syncStatus = .error(String(localized: "Temporarily unavailable"))
                @unknown default:
                    manager?.syncStatus = .unknown
                }
            }
        }
    }
    
    // MARK: - Remote Change Notifications
    // Reacts to changes arriving from other devices via CloudKit
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
    // Note: CloudKit resolves conflicts automatically
    func handleSyncConflicts() {
        // CloudKit resolves Core Data conflicts automatically.
        print("Conflict resolution is handled by CloudKit automatically")
    }
    
    // MARK: - Debugging Helpers
    // Prints CloudKit information for debugging
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
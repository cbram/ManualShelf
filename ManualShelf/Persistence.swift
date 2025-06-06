//
//  Persistence.swift
//  ManualShelf
//
//  Created by Christian Bram on 02.06.25.
//

import CoreData

struct PersistenceController {
    // Singleton-Instanz für die App
    static let shared = PersistenceController()

    @MainActor
    // Preview-Instanz für SwiftUI Previews mit Beispieldaten (nur im Speicher)
    static var preview: PersistenceController = {
        let result = PersistenceController(inMemory: true)
        let viewContext = result.container.viewContext
        for i in 0..<5 {
            let newItem = Manual(context: viewContext)
            newItem.title = "Beispiel-Manual \(i)"
            newItem.dateAdded = Date()
            
            let newFile = ManualFile(context: viewContext)
            newFile.fileName = "datei_\(i).pdf"
            newFile.fileType = "pdf"
            newFile.dateAdded = Date()
            
            newItem.addToFiles(newFile)
        }
        do {
            try viewContext.save()
        } catch {
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
        return result
    }()

    let container: NSPersistentCloudKitContainer

    // Initialisiert den Core Data Stack, optional nur im Speicher (für Tests/Previews)
    init(inMemory: Bool = false) {
        container = NSPersistentCloudKitContainer(name: "ManualShelf")
        
        if inMemory {
            // Speichert Daten nur im RAM (z.B. für Previews)
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        } else {
            // Aktiviert History Tracking und Remote Change Notifications für CloudKit Sync
            if let description = container.persistentStoreDescriptions.first {
                description.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
                description.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
            }
        }
        
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        
        // Stellt sicher, dass der ViewContext Änderungen aus dem übergeordneten Kontext automatisch zusammenführt.
        container.viewContext.automaticallyMergesChangesFromParent = true
        // Bei Konflikten werden lokale Änderungen bevorzugt.
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }
    
    // Aktualisiert die Sync-Einstellung für CloudKit (WLAN oder WLAN+Mobilfunk)
    func updateCloudKitContainerCellularAccess(allowed: Bool) {
        if allowed {
            AppSettings.shared.syncPreference = .wifiAndCellular
        } else {
            AppSettings.shared.syncPreference = .wifiOnly
        }
        print("Die Einstellung für den Mobilfunkzugriff wurde auf '\(allowed)' geändert. Die Änderung wird beim nächsten App-Start oder bei einer Neuinitialisierung des Core Data Stacks wirksam.")
    }
}

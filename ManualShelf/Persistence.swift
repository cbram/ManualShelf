//
//  Persistence.swift
//  ManualShelf
//
//  Created by Christian Bram on 02.06.25.
//

import CoreData

struct PersistenceController {
    // Shared instance for the app
    static let shared = PersistenceController()

    @MainActor
    // Preview instance with sample data for SwiftUI previews (in memory only)
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

    // Sets up the Core Data stack, optionally in memory only (tests/previews)
    init(inMemory: Bool = false) {
        container = NSPersistentCloudKitContainer(name: "ManualShelf")
        
        if inMemory {
            // Keeps data in memory only (e.g. for previews)
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        } else {
            // Enables history tracking and remote change notifications for CloudKit sync
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
        
        // Makes the view context merge changes from its parent automatically.
        container.viewContext.automaticallyMergesChangesFromParent = true
        // On conflicts, local changes win.
        container.viewContext.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
    }
}

//
//  Persistence.swift
//  ManualShelf
//
//  Created by Christian Bram on 02.06.25.
//

import CoreData

struct PersistenceController {
    static let shared = PersistenceController()

    @MainActor
    static let preview: PersistenceController = {
        let result = PersistenceController(inMemory: true)
        let viewContext = result.container.viewContext
        
        // Beispiel-Manuals für Preview erstellen
        let sampleTitles = [
            "iPhone 15 Bedienungsanleitung",
            "MacBook Pro Benutzerhandbuch",
            "AirPods Pro Manual",
            "iPad Air Anleitung"
        ]
        
        for (index, title) in sampleTitles.enumerated() {
            let manual = Manual(context: viewContext)
            manual.title = title
            manual.fileName = "\(title.lowercased().replacingOccurrences(of: " ", with: "_")).pdf"
            manual.dateAdded = Date().addingTimeInterval(TimeInterval(-index * 86400)) // Verschiedene Daten
            manual.fileData = Data() // Leere Daten für Preview
        }
        
        do {
            try viewContext.save()
        } catch {
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
        return result
    }()

    let container: NSPersistentContainer

    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "ManualShelf")
        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        }
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                /*
                 Typical reasons for an error here include:
                 * The parent directory does not exist, cannot be created, or disallows writing.
                 * The persistent store is not accessible, due to permissions or data protection when the device is locked.
                 * The device is out of space.
                 * The store could not be migrated to the current model version.
                 Check the error message to determine what the actual problem was.
                 */
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        container.viewContext.automaticallyMergesChangesFromParent = true
    }
}

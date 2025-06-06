//
//  Persistence.swift
//  ManualShelf
//
//  Created by Christian Bram on 02.06.25.
//

import CoreData
// import CloudKit // Temporär deaktiviert

struct PersistenceController {
    static let shared = PersistenceController()

    @MainActor
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

    // Zurück zu NSPersistentContainer temporär
    let container: NSPersistentCloudKitContainer
    // Definiere den Container Identifier hier, um Konsistenz zu gewährleisten
    // private let cloudKitContainerIdentifier = "iCloud.com.chrisbram.ManualShelf"

    init(inMemory: Bool = false) {
        container = NSPersistentCloudKitContainer(name: "ManualShelf")
        
        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        } else {
            // CloudKit Integration temporär deaktiviert
            if let description = container.persistentStoreDescriptions.first {
                description.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
                description.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
                // CloudKit-spezifische Konfiguration entfernt
            }
        }
        
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        
        // Core Data Konfiguration für bessere Performance
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }
    
    // Methode zum Aktualisieren der Mobilfunkzugriffs-Einstellung in AppSettings
    func updateCloudKitContainerCellularAccess(allowed: Bool) {
        if allowed {
            AppSettings.shared.syncPreference = .wifiAndCellular // Passe dies ggf. an deine AppSettings an
        } else {
            AppSettings.shared.syncPreference = .wifiOnly      // Passe dies ggf. an deine AppSettings an
        }
        print("Die Einstellung für den Mobilfunkzugriff wurde auf '\\(allowed)' geändert. Die Änderung wird beim nächsten App-Start oder bei einer Neuinitialisierung des Core Data Stacks wirksam.")
    }
}

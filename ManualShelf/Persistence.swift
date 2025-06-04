//
//  Persistence.swift
//  ManualShelf
//
//  Created by Christian Bram on 02.06.25.
//

import CoreData
import CloudKit // Wieder aktiviert

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
            manual.pdfRotationDegrees = 0
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

    // Zurück zu NSPersistentCloudKitContainer
    let container: NSPersistentCloudKitContainer
    // Definiere den Container Identifier hier, um Konsistenz zu gewährleisten
    private let cloudKitContainerIdentifier = "iCloud.com.chrisbram.ManualShelf"

    init(inMemory: Bool = false) {
        container = NSPersistentCloudKitContainer(name: "ManualShelf")
        
        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        } else {
            // CloudKit-Konfiguration wiederhergestellt
            guard let description = container.persistentStoreDescriptions.first else {
                fatalError("### Failed to retrieve a persistent store description.")
            }
            
            description.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
            description.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
            
            // NSPersistentCloudKitContainerOptions setzen
            let options = NSPersistentCloudKitContainerOptions(containerIdentifier: cloudKitContainerIdentifier)
            
            // allowsCellularAccess hier auf den Optionen setzen - AUSKOMMENTIERT, da in der Doku für Xcode 16.4 SDK nicht gefunden
            // options.allowsCellularAccess = (AppSettings.shared.syncPreference == .wifiAndCellular)
            description.cloudKitContainerOptions = options
        }
        
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        
        container.viewContext.automaticallyMergesChangesFromParent = true
        // CloudKit-spezifische Konfiguration für Query Generations
        do {
            try container.viewContext.setQueryGenerationFrom(.current)
        } catch {
            fatalError("### Failed to pin viewContext to the current generation: \(error)")
        }
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

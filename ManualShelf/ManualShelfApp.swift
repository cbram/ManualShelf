//
//  ManualShelfApp.swift
//  ManualShelf
//
//  Created by Christian Bram on 02.06.25.
//

import SwiftUI

@main
struct ManualShelfApp: App {
    let persistenceController = Self.makePersistenceController()

    var body: some Scene {
        WindowGroup {
            ManualsListView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }

    // UI tests launch with this argument to get the in-memory sample data instead of the user's store
    static let uiTestSampleDataArgument = "-uiTestSampleData"
    // App Store screenshots launch with this argument to get the localized demo data (SPEC-005)
    static let storeScreenshotDataArgument = "-storeScreenshotData"
    private static let germanLanguageCode = "de"

    @MainActor
    private static func makePersistenceController() -> PersistenceController {
        #if DEBUG
        let arguments = ProcessInfo.processInfo.arguments
        if arguments.contains(uiTestSampleDataArgument) {
            return PersistenceController.preview
        }
        if arguments.contains(storeScreenshotDataArgument) {
            let isGerman = Locale.preferredLanguages.first?.hasPrefix(germanLanguageCode) ?? false
            return PersistenceController.storeScreenshotData(german: isGerman)
        }
        #endif
        return PersistenceController.shared
    }
}

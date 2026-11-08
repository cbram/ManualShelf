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

    @MainActor
    private static func makePersistenceController() -> PersistenceController {
        #if DEBUG
        if ProcessInfo.processInfo.arguments.contains(uiTestSampleDataArgument) {
            return PersistenceController.preview
        }
        #endif
        return PersistenceController.shared
    }
}

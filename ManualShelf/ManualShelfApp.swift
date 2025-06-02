//
//  ManualShelfApp.swift
//  ManualShelf
//
//  Created by Christian Bram on 02.06.25.
//

import SwiftUI

@main
struct ManualShelfApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ManualsListView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}

//
//  ContentView.swift
//  ManualShelf
//
//  Created by Christian Bram on 02.06.25.
//

import SwiftUI
import CoreData

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext

    var body: some View {
        // Einstiegspunkt: Zeigt die Liste aller Manuals
        ManualsListView()
    }
}

// Vorschau für SwiftUI Previews
#Preview {
    ContentView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}

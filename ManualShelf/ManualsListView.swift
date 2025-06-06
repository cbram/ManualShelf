//
//  ManualsListView.swift
//  ManualShelf
//
//  Created by Christian Bram on 02.06.25.
//

import SwiftUI

struct ManualsListView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @State private var showingAddManualView = false
    @State private var showingSettingsView = false
    @State private var currentSortOption: SortOption = .dateAddedDescending
    @State private var searchText: String = ""

    var body: some View {
        NavigationView {
            VStack {
                // Die FetchedManualsDisplayView zeigt die gefilterte und sortierte Liste an.
                FetchedManualsDisplayView(
                    sortDescriptors: currentSortOption.sortDescriptors, 
                    predicate: createPredicate()
                )
                .searchable(text: $searchText, prompt: "Suche nach Titel oder Datei")
            }
            .navigationTitle("ManualShelf")
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarLeading) {
                    CloudKitSyncStatusView()
                }
                
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    Button(action: { showingAddManualView = true }) {
                        Image(systemName: "plus")
                    }
                    EditButton()
                }

                ToolbarItemGroup(placement: .bottomBar) {
                    Menu {
                        Picker("Sortieren", selection: $currentSortOption) {
                            ForEach(SortOption.allCases) { option in
                                Text(option.rawValue).tag(option)
                            }
                        }
                    } label: {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                    }

                    Spacer()

                    Button(action: { showingSettingsView = true }) {
                        Image(systemName: "gearshape.fill")
                    }
                }
            }
            .sheet(isPresented: $showingAddManualView) {
                NavigationView {
                    AddManualView()
                }
            }
            .sheet(isPresented: $showingSettingsView) {
                SettingsView()
            }
            
            // Standard Detail View für iPad
            VStack {
                Image(systemName: "books.vertical")
                    .font(.system(size: 60))
                    .foregroundColor(.secondary)
                Text("Wählen Sie ein Manual aus")
                    .font(.title2)
                    .foregroundColor(.secondary)
            }
        }
        .navigationViewStyle(DoubleColumnNavigationViewStyle())
    }
    
    private func createPredicate() -> NSPredicate? {
        if searchText.isEmpty {
            return nil
        } else {
            return NSPredicate(format: "title CONTAINS[cd] %@ OR ANY files.fileName CONTAINS[cd] %@", searchText, searchText)
        }
    }
}

#Preview {
    ManualsListView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
} 
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
    @FetchRequest(
        entity: ManualTag.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \ManualTag.name, ascending: true)]
    ) var allTags: FetchedResults<ManualTag>
    @State private var selectedFilterTag: ManualTag? = nil

    var body: some View {
        NavigationView {
            VStack {
                // Tag-Filterleiste
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        ForEach(usedTags, id: \.objectID) { tag in
                            TagFilterChip(
                                tag: tag,
                                isSelected: selectedFilterTag == tag,
                                onTap: {
                                    if selectedFilterTag == tag {
                                        selectedFilterTag = nil
                                    } else {
                                        selectedFilterTag = tag
                                    }
                                }
                            )
                        }
                    }
                    .padding(.horizontal)
                }
                // Zeigt die gefilterte und sortierte Liste der Manuals an
                FetchedManualsDisplayView(
                    sortDescriptors: currentSortOption.sortDescriptors, 
                    predicate: createPredicate(),
                    selectedFilterTag: selectedFilterTag
                )
                .onAppear {
                    // Trigger ein Refresh, indem der ViewContext geändert wird (z.B. durch Zuweisung)
                    // oder ein State-Update, falls nötig
                    // (SwiftUI refresht FetchRequest bei onAppear automatisch, aber dies stellt sicher, dass es passiert)
                    _ = viewContext
                }
                .searchable(text: $searchText, prompt: "Suche nach Titel oder Datei")
            }
            .navigationTitle("ManualShelf")
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    // Öffnet das Sheet zum Hinzufügen eines neuen Manuals
                    Button(action: { showingAddManualView = true }) {
                        Image(systemName: "plus")
                    }
                    EditButton()
                }

                ToolbarItemGroup(placement: .bottomBar) {
                    // Menü zur Auswahl der Sortieroption
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

                    // Öffnet die Einstellungen
                    Button(action: { showingSettingsView = true }) {
                        Image(systemName: "gearshape.fill")
                    }
                }
            }
            // Sheet zum Hinzufügen eines neuen Manuals
            .sheet(isPresented: $showingAddManualView) {
                NavigationView {
                    AddManualView()
                }
            }
            // Sheet für die Einstellungen
            .sheet(isPresented: $showingSettingsView) {
                SettingsView()
            }
            
            // Platzhalter-View für iPad, wenn kein Manual ausgewählt ist
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
    
    // Erstellt ein Predicate für die Suche nach Titel oder Dateiname
    private func createPredicate() -> NSPredicate? {
        if searchText.isEmpty {
            return nil
        } else {
            return NSPredicate(format: "title CONTAINS[cd] %@ OR ANY files.fileName CONTAINS[cd] %@", searchText, searchText)
        }
    }

    // Filtere die Tag-Filterleiste so, dass nur verwendete Tags angezeigt werden
    var usedTags: [ManualTag] {
        allTags.filter { tag in
            (tag.manuals?.count ?? 0) > 0
        }
    }
}

struct TagFilterChip: View {
    let tag: ManualTag
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            Text(tag.name ?? "")
                .padding(8)
                .background(isSelected ? Color.accentColor : Color.gray.opacity(0.2))
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(12)
        }
    }
}

#Preview {
    ManualsListView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
} 
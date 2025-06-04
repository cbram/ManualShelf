//
//  ManualsListView.swift
//  ManualShelf
//
//  Created by Christian Bram on 02.06.25.
//

import SwiftUI
import CoreData

struct ManualsListView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @State private var showingAddManual = false
    @State private var showingSettingsView = false // Zustand für die Settings-Ansicht
    
    // Zustand für die aktuelle Sortierung
    @State private var currentSortOption: SortOption = .dateAddedDescending
    @State private var searchText: String = "" // Zustand für den Suchtext
    
    // Die @FetchRequest wird in eine Sub-View verschoben
    // @FetchRequest(
    //     sortDescriptors: [NSSortDescriptor(keyPath: \Manual.dateAdded, ascending: false)],
    //     animation: .default)
    // private var manuals: FetchedResults<Manual>
    
    var body: some View {
        NavigationView {
            // Die FetchedManualsDisplayView zeigt die gefilterte und sortierte Liste an.
            // Sie wird jetzt auch mit dem Suchprädikat initialisiert.
            FetchedManualsDisplayView(
                sortDescriptors: currentSortOption.sortDescriptors, 
                predicate: createPredicate() // NSPredicate wird hier erstellt
            )
            // Der .searchable Modifier wird direkt hier angewendet, um die Suchleiste bereitzustellen.
            // Der Suchtext wird an $searchText gebunden.
            .searchable(text: $searchText, prompt: "Suche nach Titel oder Datei")
            .navigationTitle("ManualShelf") // NavigationTitle für die primäre Ansicht der Navigation
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarLeading) {
                    CloudKitSyncStatusView()
                }
                
                // Obere rechte Toolbar: Nur noch Add und Edit Button
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    Button(action: { showingAddManual = true }) {
                        Image(systemName: "plus")
                    }
                    EditButton()
                }
                
                // Untere Toolbar: Filter-Button links, Settings-Button rechts
                ToolbarItemGroup(placement: .bottomBar) {
                    // Menu-Button für die Sortierung (Filter-Icon) jetzt links
                    Menu {
                        Picker("Sortieren", selection: $currentSortOption) {
                            ForEach(SortOption.allCases) { option in
                                Text(option.rawValue).tag(option)
                            }
                        }
                    } label: {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                    }

                    Spacer() // Schiebt das Settings-Icon nach rechts

                    Button { // Settings-Icon
                        showingSettingsView = true
                    } label: {
                        Image(systemName: "gearshape.fill")
                    }
                }
            }
            .sheet(isPresented: $showingAddManual) {
                AddManualView()
                    .environment(\.managedObjectContext, viewContext)
            }
            // Sheet für die Einstellungen
            .sheet(isPresented: $showingSettingsView) {
                SettingsView()
            }
            
            // Standard Detail View für iPad (rechte Spalte, wenn nichts ausgewählt ist)
            VStack {
                Image(systemName: "books.vertical")
                    .font(.system(size: 60))
                    .foregroundColor(.secondary)
                Text("Wählen Sie ein Manual aus")
                    .font(.title2)
                    .foregroundColor(.secondary)
                Text("Tippen Sie auf ein Manual in der Liste, um es zu öffnen")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
        }
        .navigationViewStyle(DoubleColumnNavigationViewStyle()) // Behält den iPad-Stil bei
    }
    
    // Hilfsfunktion zum Erstellen des Prädikats für die Suche
    private func createPredicate() -> NSPredicate? {
        if searchText.isEmpty {
            return nil
        } else {
            // Sucht in 'title' UND 'fileName'. '[cd]' bedeutet case- und diacritic-insensitive.
            return NSPredicate(format: "title CONTAINS[cd] %@ OR fileName CONTAINS[cd] %@", searchText, searchText)
        }
    }
    
    // Die deleteManuals Funktion wird in FetchedManualsDisplayView benötigt, da sie auf die FetchedResults zugreift.
    // private func deleteManuals(offsets: IndexSet) { ... }
}

// Preview muss ggf. angepasst werden, wenn die Hauptlogik ausgelagert wird.
#Preview {
   ManualsListView()
       .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
} 
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
                // Tag filter bar
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
                // Shows the filtered and sorted list of manuals
                FetchedManualsDisplayView(
                    sortDescriptors: currentSortOption.sortDescriptors, 
                    predicate: createPredicate(),
                    selectedFilterTag: selectedFilterTag
                )
                .onAppear {
                    // Trigger a refresh by touching the view context (e.g. by assignment)
                    // or by a state update if needed
                    // (SwiftUI refreshes the fetch request on appear anyway; this makes sure it happens)
                    _ = viewContext
                }
                .searchable(text: $searchText, prompt: Text("Search by title or file"))
            }
            .navigationTitle("ManualShelf")
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    // Opens the sheet to add a new manual
                    Button(action: { showingAddManualView = true }) {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("Add Manual")
                    EditButton()
                }

                ToolbarItemGroup(placement: .bottomBar) {
                    // Menu to choose the sort option
                    Menu {
                        Picker("Sort", selection: $currentSortOption) {
                            ForEach(SortOption.allCases) { option in
                                Text(option.title).tag(option)
                            }
                        }
                    } label: {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                    }
                    .accessibilityLabel("Sort")

                    Spacer()

                    // Opens the settings
                    Button(action: { showingSettingsView = true }) {
                        Image(systemName: "gearshape.fill")
                    }
                    .accessibilityLabel("Settings")
                }
            }
            // Sheet to add a new manual
            .sheet(isPresented: $showingAddManualView) {
                NavigationView {
                    AddManualView()
                }
            }
            // Sheet for the settings
            .sheet(isPresented: $showingSettingsView) {
                SettingsView()
            }
            
            // Placeholder on iPad while no manual is selected
            VStack {
                Image(systemName: "books.vertical")
                    .font(.system(size: 60))
                    .foregroundColor(.secondary)
                Text("Select a manual")
                    .font(.title2)
                    .foregroundColor(.secondary)
            }
        }
        .navigationViewStyle(DoubleColumnNavigationViewStyle())
    }
    
    // Builds the predicate for searching by title or file name
    private func createPredicate() -> NSPredicate? {
        if searchText.isEmpty {
            return nil
        } else {
            return NSPredicate(format: "title CONTAINS[cd] %@ OR ANY files.fileName CONTAINS[cd] %@", searchText, searchText)
        }
    }

    // Limit the tag filter bar to tags that are in use
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
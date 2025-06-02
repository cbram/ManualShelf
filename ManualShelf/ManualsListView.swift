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
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Manual.dateAdded, ascending: false)],
        animation: .default)
    private var manuals: FetchedResults<Manual>
    
    var body: some View {
        NavigationView {
            List {
                ForEach(manuals) { manual in
                    NavigationLink(destination: PDFViewerView(manual: manual)) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(manual.title ?? "Unbekanntes Manual")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            Text(manual.fileName ?? "")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Text("Hinzugefügt: \(manual.dateAdded ?? Date(), formatter: dateFormatter)")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                }
                .onDelete(perform: deleteManuals)
            }
            .navigationTitle("ManualShelf")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    EditButton()
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddManual = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddManual) {
                AddManualView()
                    .environment(\.managedObjectContext, viewContext)
            }
            
            // Standard Detail View für iPad
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
        .navigationViewStyle(DoubleColumnNavigationViewStyle())
    }
    
    private func deleteManuals(offsets: IndexSet) {
        withAnimation {
            offsets.map { manuals[$0] }.forEach(viewContext.delete)
            
            do {
                try viewContext.save()
            } catch {
                print("Fehler beim Löschen: \(error)")
            }
        }
    }
}

private let dateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .medium
    formatter.timeStyle = .short
    return formatter
}()

#Preview {
    ManualsListView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
} 
import SwiftUI
import CoreData

struct FetchedManualsDisplayView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    // Die @FetchRequest wird hier basierend auf den übergebenen Parametern initialisiert.
    @FetchRequest private var manuals: FetchedResults<Manual>

    // Initializer, um die FetchRequest dynamisch zu konfigurieren
    init(sortDescriptors: [NSSortDescriptor], predicate: NSPredicate?) {
        _manuals = FetchRequest<Manual>(
            sortDescriptors: sortDescriptors,
            predicate: predicate,
            animation: .default
        )
    }

    var body: some View {
        Group { // Group wird verwendet, damit wir hier eine .toolbar für den EditButton haben könnten, falls nötig.
            if manuals.isEmpty {
                VStack(spacing: 20) {
                    Image(systemName: "tray.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.secondary)
                    Text("Keine Manuals vorhanden")
                        .font(.title2)
                        .foregroundColor(.secondary)
                    Text("Tippe auf das Plus-Symbol (+), um dein erstes Manual hinzuzufügen, oder ändere deine Filter-/Sortiereinstellungen.")
                        .font(.callout)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
            } else {
                List {
                    ForEach(manuals) { manual in
                        NavigationLink(destination: PDFViewerView(manual: manual)) {
                            HStack(spacing: 12) {
                                Image(systemName: "doc.text.fill")
                                    .font(.title2)
                                    .foregroundColor(.accentColor)
                                    .frame(width: 25, alignment: .center)

                                VStack(alignment: .leading, spacing: 4) {
                                    Text(manual.title ?? "Unbekanntes Manual")
                                        .font(.headline)
                                        .foregroundColor(.primary)
                                    
                                    Text(manual.fileName ?? "")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .lineLimit(1)
                                    
                                    Text("Hinzugefügt: \(manual.dateAdded ?? Date(), formatter: dateFormatter)")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                            }
                            .padding(.vertical, 6)
                        }
                    }
                    .onDelete(perform: deleteManuals)
                }
            }
        }
    }

    private func deleteManuals(offsets: IndexSet) {
        withAnimation {
            offsets.map { manuals[$0] }.forEach(viewContext.delete)
            
            do {
                try viewContext.save()
            } catch {
                // Hier wäre eine Fehlerbehandlung für den Benutzer sinnvoll (z.B. Alert)
                print("Fehler beim Löschen: \(error.localizedDescription)")
                // Beispiel für Alert (müsste @State Variablen in der View haben):
                // self.alertTitle = "Fehler beim Löschen"
                // self.alertMessage = error.localizedDescription
                // self.showingAlert = true
            }
        }
    }
}

// Der DateFormatter, der vorher in ManualsListView war.
private let dateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .medium
    formatter.timeStyle = .short
    return formatter
}()

// Preview für FetchedManualsDisplayView
struct FetchedManualsDisplayView_Previews: PreviewProvider {
    static var previews: some View {
        // Erstelle ein paar Beispieldaten für die Vorschau
        let context = PersistenceController.preview.container.viewContext
        let manual1 = Manual(context: context)
        manual1.title = "Anleitung Kaffeemaschine"
        manual1.fileName = "kaffee.pdf"
        manual1.dateAdded = Calendar.current.date(byAdding: .day, value: -1, to: Date())!

        let manual2 = Manual(context: context)
        manual2.title = "Handbuch Fernseher"
        manual2.fileName = "tv.pdf"
        manual2.dateAdded = Date()
        
        return FetchedManualsDisplayView(
            sortDescriptors: SortOption.dateAddedDescending.sortDescriptors,
            predicate: nil
        )
        .environment(\.managedObjectContext, context)
    }
} 
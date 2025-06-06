import SwiftUI
import CoreData
import UniformTypeIdentifiers

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
                        NavigationLink(destination: ManualDisplayView(manual: manual)) {
                            ManualRow(manual: manual)
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

// Die Row-Darstellung, angepasst an die neue Datenstruktur
struct ManualRow: View {
    @ObservedObject var manual: Manual

    var body: some View {
        HStack(spacing: 12) {
            let sortedFiles = (manual.files as? Set<ManualFile> ?? []).sorted {
                $0.dateAdded ?? Date.distantPast < $1.dateAdded ?? Date.distantPast
            }

            if let firstFile = sortedFiles.first {
                Image(systemName: firstFile.fileType == UTType.pdf.preferredFilenameExtension ? "doc.text.fill" : "photo.fill")
                    .font(.title2)
                    .foregroundColor(.accentColor)
                    .frame(width: 25, alignment: .center)
            } else {
                Image(systemName: "doc.questionmark.fill")
                    .font(.title2)
                    .foregroundColor(.gray)
                    .frame(width: 25, alignment: .center)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(manual.title ?? "Unbekanntes Manual")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text("\(manual.files?.count ?? 0) Datei(en) - Hinzugefügt: \(manual.dateAdded ?? Date(), formatter: dateFormatter)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
        }
        .padding(.vertical, 6)
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
        manual1.dateAdded = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        
        let file1 = ManualFile(context: context)
        file1.fileName = "kaffee.pdf"
        file1.fileType = "pdf"
        file1.dateAdded = Date()
        manual1.addToFiles(file1)

        let manual2 = Manual(context: context)
        manual2.title = "Handbuch Fernseher"
        manual2.dateAdded = Date()
        
        let file2 = ManualFile(context: context)
        file2.fileName = "tv.jpeg"
        file2.fileType = "jpeg"
        file2.dateAdded = Date()
        manual2.addToFiles(file2)
        
        return FetchedManualsDisplayView(
            sortDescriptors: SortOption.dateAddedDescending.sortDescriptors,
            predicate: nil
        )
        .environment(\.managedObjectContext, context)
    }
} 
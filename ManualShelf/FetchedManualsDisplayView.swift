import SwiftUI
import CoreData
import UniformTypeIdentifiers

struct FetchedManualsDisplayView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    // Die @FetchRequest wird hier basierend auf den übergebenen Parametern initialisiert.
    @FetchRequest private var manuals: FetchedResults<Manual>
    var selectedFilterTag: ManualTag? = nil

    // Initializer, um die FetchRequest dynamisch zu konfigurieren
    init(sortDescriptors: [NSSortDescriptor], predicate: NSPredicate?, selectedFilterTag: ManualTag?) {
        _manuals = FetchRequest<Manual>(
            sortDescriptors: sortDescriptors,
            predicate: predicate,
            animation: .default
        )
        self.selectedFilterTag = selectedFilterTag
    }

    var filteredManuals: [Manual] {
        if let tag = selectedFilterTag {
            return manuals.filter { manual in
                let files = manual.files as? Set<ManualFile> ?? []
                return files.contains { file in
                    let tags = file.manualTags as? Set<ManualTag> ?? []
                    return tags.contains(tag)
                }
            }
        } else {
            return Array(manuals)
        }
    }

    var body: some View {
        Group { // Group wird verwendet, damit wir hier eine .toolbar für den EditButton haben könnten, falls nötig.
            if filteredManuals.isEmpty {
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
                    ForEach(filteredManuals) { manual in
                        NavigationLink(destination: ManualDisplayView(manual: manual)) {
                            ManualRow(manual: manual)
                        }
                        .buttonStyle(PlainButtonStyle())
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
                print("Fehler beim Löschen des Manuals: \(error.localizedDescription)")
            }
        }
    }
}

// Die Row-Darstellung, angepasst an die neue Datenstruktur
struct ManualRow: View {
    @ObservedObject var manual: Manual

    // Farbenblindenfreundliche Farbpalette mit passenden Schriftfarben
    private let tagColors: [(bg: Color, fg: Color)] = [
        (Color(red: 0.00, green: 0.45, blue: 0.70), .white),      // Blau
        (Color(red: 0.34, green: 0.71, blue: 0.91), .black),      // Türkis
        (Color(red: 0.90, green: 0.63, blue: 0.00), .black),      // Orange
        (Color(red: 0.94, green: 0.89, blue: 0.26), .black),      // Gelb
        (Color(red: 0.27, green: 0.62, blue: 0.28), .white),      // Grün
        (Color(red: 0.55, green: 0.34, blue: 0.64), .white),      // Violett
        (Color(red: 0.80, green: 0.48, blue: 0.74), .white),      // Pink
        (Color(red: 0.27, green: 0.27, blue: 0.27), .white)       // Dunkelgrau
    ]
    // Liefert alle zugehörigen Tags (über alle Files)
    private var tags: [ManualTag] {
        let files = manual.files as? Set<ManualFile> ?? []
        let tags = files.flatMap { ($0.manualTags as? Set<ManualTag>) ?? [] }
        return Array(Set(tags)).sorted { ($0.name ?? "") < ($1.name ?? "") }
    }
    // Weise pro Row jedem Tag eine eindeutige Farbe zu
    private func colorMapForTags(_ tags: [ManualTag]) -> [ManualTag: (bg: Color, fg: Color)] {
        var map: [ManualTag: (bg: Color, fg: Color)] = [:]
        var usedIndices: Set<Int> = []
        for (i, tag) in tags.enumerated() {
            // Finde die nächste freie Farbe
            var colorIdx = abs((tag.name?.hashValue ?? i) % tagColors.count)
            while usedIndices.contains(colorIdx) {
                colorIdx = (colorIdx + 1) % tagColors.count
            }
            usedIndices.insert(colorIdx)
            map[tag] = tagColors[colorIdx]
        }
        return map
    }
    var body: some View {
        let colorMap = colorMapForTags(tags)
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
                // Tags als farbige Chips anzeigen
                if !tags.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 4) {
                            ForEach(tags, id: \.objectID) { tag in
                                let color = colorMap[tag] ?? tagColors[0]
                                Text(tag.name ?? "")
                                    .font(.caption)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(color.bg)
                                    .foregroundColor(color.fg)
                                    .cornerRadius(8)
                                    .allowsHitTesting(false)
                            }
                        }
                    }
                }
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
            predicate: nil,
            selectedFilterTag: nil
        )
        .environment(\.managedObjectContext, context)
    }
} 
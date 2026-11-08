import SwiftUI
import CoreData
import UniformTypeIdentifiers

struct FetchedManualsDisplayView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    // The @FetchRequest is configured from the parameters passed in.
    @FetchRequest private var manuals: FetchedResults<Manual>
    var selectedFilterTag: ManualTag? = nil

    // Initializer that configures the fetch request dynamically
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
        Group { // Group leaves room for a .toolbar with the EditButton if needed.
            if filteredManuals.isEmpty {
                VStack(spacing: 20) {
                    Image(systemName: "tray.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.secondary)
                    Text("No Manuals")
                        .font(.title2)
                        .foregroundColor(.secondary)
                    Text("Tap the plus button (+) to add your first manual, or change your filter or sort settings.")
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
                print("Failed to delete manual: \(error.localizedDescription)")
            }
        }
    }
}

// Row for one manual in the list
struct ManualRow: View {
    @ObservedObject var manual: Manual

    private static let thumbnailSize: CGFloat = 44

    // All tags of the manual (across all files)
    private var tags: [ManualTag] {
        let files = manual.files as? Set<ManualFile> ?? []
        let tags = files.flatMap { ($0.manualTags as? Set<ManualTag>) ?? [] }
        return Array(Set(tags)).sorted { ($0.name ?? "") < ($1.name ?? "") }
    }
    var body: some View {
        HStack(spacing: 12) {
            let sortedFiles = (manual.files as? Set<ManualFile> ?? []).sorted {
                $0.dateAdded ?? Date.distantPast < $1.dateAdded ?? Date.distantPast
            }
            if let firstFile = sortedFiles.first {
                FileThumbnailView(file: firstFile, size: Self.thumbnailSize)
            } else {
                Image(systemName: "doc.questionmark.fill")
                    .font(.title2)
                    .foregroundColor(.gray)
                    .frame(width: Self.thumbnailSize, height: Self.thumbnailSize)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(manual.title ?? String(localized: "Unknown Manual"))
                    .font(.headline)
                    .foregroundColor(.primary)
                // Show tags as coloured chips. A scroll view swallows taps, so it is only used
                // when the chips do not fit; otherwise a tap on the chips opens the manual (SPEC-004).
                if !tags.isEmpty {
                    ViewThatFits(in: .horizontal) {
                        tagChips
                        ScrollView(.horizontal, showsIndicators: false) {
                            tagChips
                        }
                    }
                }
                Text("\(String(localized: "\(manual.files?.count ?? 0) files")) - Added: \(manual.dateAdded ?? Date(), formatter: dateFormatter)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
        }
        .padding(.vertical, 6)
    }

    private var tagChips: some View {
        HStack(spacing: 4) {
            ForEach(tags, id: \.objectID) { tag in
                let color = TagColor.forName(tag.name)
                Text(tag.name ?? "")
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(color.background)
                    .foregroundColor(color.foreground)
                    .cornerRadius(8)
                    .allowsHitTesting(false)
            }
        }
    }
}

// Date formatter for the row's date line
private let dateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .medium
    formatter.timeStyle = .short
    return formatter
}()

// Preview for FetchedManualsDisplayView
struct FetchedManualsDisplayView_Previews: PreviewProvider {
    static var previews: some View {
        // Create some sample data for the preview
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
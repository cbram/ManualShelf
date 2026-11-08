//
//  ManualDisplayView.swift
//  ManualShelf
//
//  Created by Christian Bram on 02.06.25.
//

import SwiftUI
import CoreData
import PDFKit // PDF display
import UniformTypeIdentifiers // File type detection

struct ManualDisplayView: View {
    @ObservedObject var manual: Manual
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        entity: ManualTag.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \ManualTag.name, ascending: true)]
    ) var allTags: FetchedResults<ManualTag>
    @State private var tagInput: String = ""
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    @State private var showingAlert = false
    @State private var showingAddFilePicker = false
    @State private var showingURLDownload = false
    @State private var displayedTags: [ManualTag] = []
    @State private var shareURLs: [URL] = []
    @State private var fileToRename: ManualFile?
    @State private var renameText = ""
    @State private var showingRename = false

    private static let fileThumbnailSize: CGFloat = 36
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Tag editing
            Text("Tags")
                .font(.headline)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack {
                    ForEach(displayedTags, id: \.objectID) { tag in
                        let tagColor = TagColor.forName(tag.name)
                        // The remove button sits inside the chip so it shares the chip's
                        // text colour and contrast.
                        HStack(spacing: 4) {
                            Text(tag.name ?? "")
                                .foregroundColor(tagColor.foreground)
                            Button(action: { removeTag(tag) }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(tagColor.foreground)
                            }
                            .accessibilityLabel("Remove tag \(tag.name ?? "")")
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(tagColor.background)
                        .cornerRadius(12)
                        .padding(2)
                    }
                }
            }
            // Tag input with autocompletion
            HStack {
                TextField("Add tag...", text: $tagInput, onCommit: { addTagIfNeeded() })
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                Button("Add") { addTagIfNeeded() }
                    .disabled(tagInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            if !tagInput.isEmpty {
                ForEach(allTags.filter { $0.name?.lowercased().contains(tagInput.lowercased()) == true && !displayedTags.contains($0) }, id: \.objectID) { tag in
                    Button(tag.name ?? "") {
                        addTag(tag)
                    }
                }
            }
            // File list
            List {
                let fileSet = manual.files as? Set<ManualFile> ?? []
                let files = fileSet.sorted { $0.dateAdded ?? Date.distantPast < $1.dateAdded ?? Date.distantPast }
                ForEach(files) { file in
                    NavigationLink(destination: FileDisplayView(manualFile: file)) {
                        HStack {
                            FileThumbnailView(file: file, size: Self.fileThumbnailSize)
                            Text(file.fileName ?? String(localized: "Unnamed File"))
                        }
                    }
                    .contextMenu {
                        Button("Rename", systemImage: "pencil") { startRename(file) }
                    }
                    .swipeActions(edge: .leading) {
                        Button("Rename", systemImage: "pencil") { startRename(file) }
                            .tint(.accentColor)
                    }
                }
                .onDelete(perform: deleteFiles)
            }
            .listStyle(PlainListStyle())
            .renameFileAlert(
                isPresented: $showingRename,
                name: $renameText,
                fileExtension: FileNaming.fileExtension(of: fileToRename?.fileName ?? "", fallback: fileToRename?.fileType),
                onRename: applyRename
            )
            .sheet(isPresented: $showingURLDownload) {
                URLDownloadView { data, name, type in
                    addFileToManual(data: data, name: name, type: type)
                }
            }
        }
        .padding()
        .navigationTitle(manual.title ?? String(localized: "Files"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button("Choose File", systemImage: "doc") {
                        showingAddFilePicker = true
                    }
                    Button("Load from URL", systemImage: "link") {
                        showingURLDownload = true
                    }
                } label: {
                    Image(systemName: "plus")
                }
                .accessibilityLabel("Add File")
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                if !shareURLs.isEmpty {
                    ShareLink(items: shareURLs) {
                        Image(systemName: "square.and.arrow.up")
                    }
                    .accessibilityLabel("Share All Files")
                }
            }
        }
        // Temporary copies for sharing, refreshed when files are added or removed
        .task(id: sortedFiles.map(\.fileName)) {
            shareURLs = sortedFiles.compactMap { try? FileExport.temporaryURL(for: $0) }
        }
        .sheet(isPresented: $showingAddFilePicker) {
            DocumentPickerView { result in
                switch result {
                case .success(let (data, name, type)):
                    addFileToManual(data: data, name: name, type: type)
                case .failure(let error):
                    self.alertTitle = String(localized: "Error Adding")
                    self.alertMessage = error.localizedDescription
                    self.showingAlert = true
                }
            }
        }
        .alert(alertTitle, isPresented: $showingAlert) {
            Button("OK") { }
        } message: {
            Text(alertMessage)
        }
        .onAppear {
            displayedTags = usedTags
        }
    }
    
    // Opens the rename alert with the file's name without extension
    private func startRename(_ file: ManualFile) {
        fileToRename = file
        renameText = FileNaming.baseName(of: file.fileName ?? "")
        showingRename = true
    }

    // Saves the typed name; the extension is kept and an empty name changes nothing
    private func applyRename() {
        guard let file = fileToRename else { return }
        let currentName = file.fileName ?? ""
        let newName = FileNaming.renamed(currentFileName: currentName, newBaseName: renameText, fallbackExtension: file.fileType)
        guard newName != currentName else { return }
        // This view only observes the manual; a change on one of its files does not
        // publish on the manual, so the row and the share copies would keep the old name.
        manual.objectWillChange.send()
        file.fileName = newName
        do {
            try viewContext.save()
        } catch {
            viewContext.rollback()
            alertTitle = String(localized: "Error Saving")
            alertMessage = String(localized: "The file could not be renamed: \(error.localizedDescription)")
            showingAlert = true
        }
    }

    // Files of the manual in the order they were added
    private var sortedFiles: [ManualFile] {
        let fileSet = manual.files as? Set<ManualFile> ?? []
        return fileSet.sorted { $0.dateAdded ?? Date.distantPast < $1.dateAdded ?? Date.distantPast }
    }

    // All tags used in this manual (across all files)
    private var usedTags: [ManualTag] {
        let files = manual.files as? Set<ManualFile> ?? []
        let tags = files.flatMap { ($0.manualTags as? Set<ManualTag>) ?? [] }
        return Array(Set(tags)).sorted { ($0.name ?? "") < ($1.name ?? "") }
    }
    
    // Adds a new file to the manual and saves it in the Core Data context
    private func addFileToManual(data: Data, name: String, type: UTType) {
        let newFile = ManualFile(context: viewContext)
        newFile.fileName = name
        newFile.fileType = type.preferredFilenameExtension
        newFile.fileData = data
        newFile.dateAdded = Date()
        newFile.pdfRotationDegrees = 0
        
        manual.addToFiles(newFile)
        
        do {
            try viewContext.save()
        } catch {
            self.alertTitle = String(localized: "Error Saving")
            self.alertMessage = String(localized: "The new file could not be added to the manual: \(error.localizedDescription)")
            self.showingAlert = true
        }
    }
    
    // Deletes individual files from the manual
    private func deleteFiles(at offsets: IndexSet) {
        let fileSet = manual.files as? Set<ManualFile> ?? []
        let files = fileSet.sorted {
            $0.dateAdded ?? Date.distantPast < $1.dateAdded ?? Date.distantPast
        }
        for index in offsets {
            let file = files[index]
            manual.removeFromFiles(file)
            viewContext.delete(file)
        }
        do {
            try viewContext.save()
        } catch {
            self.alertTitle = String(localized: "Error Deleting")
            self.alertMessage = String(localized: "The file could not be removed: \(error.localizedDescription)")
            self.showingAlert = true
        }
    }
    
    // Adds a tag (existing or new)
    private func addTagIfNeeded() {
        let trimmed = tagInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        if let existing = allTags.first(where: { $0.name?.lowercased() == trimmed.lowercased() }) {
            addTag(existing)
        } else {
            let newTag = ManualTag(context: viewContext)
            newTag.name = trimmed
            do {
                try viewContext.save()
                addTag(newTag)
            } catch {
                alertTitle = String(localized: "Error Adding")
                alertMessage = error.localizedDescription
                showingAlert = true
            }
        }
        tagInput = ""
    }
    private func addTag(_ tag: ManualTag) {
        let files = manual.files as? Set<ManualFile> ?? []
        for file in files {
            var tags = file.manualTags as? Set<ManualTag> ?? []
            if !tags.contains(tag) {
                tags.insert(tag)
                file.manualTags = NSSet(set: tags)
            }
        }
        do { try viewContext.save() } catch { print("Failed to save: \(error)") }
        displayedTags = usedTags
    }
    private func removeTag(_ tag: ManualTag) {
        let files = manual.files as? Set<ManualFile> ?? []
        for file in files {
            var tags = file.manualTags as? Set<ManualTag> ?? []
            if tags.contains(tag) {
                tags.remove(tag)
                file.manualTags = NSSet(set: tags)
            }
        }
        do {
            try viewContext.save()
            // Check whether the tag is still used anywhere
            if (tag.manuals?.count ?? 0) == 0 {
                viewContext.delete(tag)
                try? viewContext.save()
            }
        } catch { print("Failed to save: \(error)") }
        displayedTags = usedTags
    }
}

// FileDisplayView shows a single file (PDF or image) and lets the user rotate it.
struct FileDisplayView: View {
    @ObservedObject var manualFile: ManualFile
    @Environment(\.managedObjectContext) private var viewContext

    // Gallery state
    @State private var currentIndex: Int = 0
    @State private var imageRotationDegrees: Double = 0 // Image rotation
    @State private var imageScale: CGFloat = 1.0 // Zoom
    @State private var imageOffset: CGSize = .zero // Pan offset
    @State private var shareURL: URL?
    private var imageFiles: [ManualFile] = []
    
    // Initializer that sets imageFiles and currentIndex
    init(manualFile: ManualFile) {
        self.manualFile = manualFile
        if let manual = manualFile.manual,
           let fileSet = manual.files as? Set<ManualFile> {
            let images = fileSet
                .filter { file in
                    let type = file.fileType?.lowercased() ?? ""
                    return type == "jpg" || type == "jpeg" || type == "png"
                }
                .sorted { $0.dateAdded ?? Date.distantPast < $1.dateAdded ?? Date.distantPast }
            self.imageFiles = images
            self._currentIndex = State(initialValue: images.firstIndex(where: { $0.objectID == manualFile.objectID }) ?? 0)
        }
        // Load the initial image rotation from Core Data (single image view)
        if let rotation = manualFile.value(forKey: "imageRotationDegrees") as? Int16 {
            self._imageRotationDegrees = State(initialValue: Double(rotation))
        }
    }

    var body: some View {
        Group {
            if let fileData = manualFile.fileData, !fileData.isEmpty {
                if manualFile.fileType?.lowercased() == UTType.pdf.preferredFilenameExtension {
                    PDFKitView(manualFile: manualFile)
                } else if manualFile.fileType?.lowercased() == UTType.jpeg.preferredFilenameExtension || 
                          manualFile.fileType?.lowercased() == "jpg" ||
                          manualFile.fileType?.lowercased() == UTType.png.preferredFilenameExtension {
                    if imageFiles.count > 1 {
                        VStack {
                            TabView(selection: $currentIndex) {
                                ForEach(Array(imageFiles.enumerated()), id: \ .element.objectID) { (idx, file) in
                                    if let data = file.fileData, let uiImage = UIImage(data: data) {
                                        Image(uiImage: uiImage)
                                            .resizable()
                                            .scaledToFit()
                                            .rotationEffect(.degrees(idx == currentIndex ? imageRotationDegrees : 0))
                                            .scaleEffect(idx == currentIndex ? imageScale : 1.0)
                                            .offset(idx == currentIndex ? imageOffset : .zero)
                                            .gesture(
                                                SimultaneousGesture(
                                                    MagnificationGesture()
                                                        .onChanged { value in
                                                            if idx == currentIndex {
                                                                imageScale = value
                                                            }
                                                        }
                                                        .onEnded { _ in
                                                            if imageScale < 1.0 { imageScale = 1.0 }
                                                            if imageScale > 5.0 { imageScale = 5.0 }
                                                            if imageScale == 1.0 { imageOffset = .zero }
                                                        },
                                                    DragGesture()
                                                        .onChanged { value in
                                                            if idx == currentIndex && imageScale > 1.0 {
                                                                imageOffset = value.translation
                                                            }
                                                        }
                                                        .onEnded { _ in
                                                            if imageScale == 1.0 { imageOffset = .zero }
                                                        }
                                                )
                                            )
                                            .tag(idx)
                                    } else {
                                        errorView(message: "The image could not be loaded.")
                                    }
                                }
                            }
                            .tabViewStyle(PageTabViewStyle())
                            HStack(alignment: .center, spacing: 32) {
                                Button(action: {
                                    if currentIndex > 0 { currentIndex -= 1; imageRotationDegrees = 0; imageScale = 1.0; imageOffset = .zero }
                                }) {
                                    Image(systemName: "chevron.left.circle.fill")
                                        .font(.system(size: 36))
                                        .opacity(currentIndex > 0 ? 0.8 : 0.3)
                                }
                                .accessibilityLabel("Previous Image")
                                .disabled(currentIndex == 0)
                                Text("\(currentIndex + 1) of \(imageFiles.count)")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .frame(minWidth: 80)
                                Button(action: {
                                    if currentIndex < imageFiles.count - 1 { currentIndex += 1; imageRotationDegrees = 0; imageScale = 1.0; imageOffset = .zero }
                                }) {
                                    Image(systemName: "chevron.right.circle.fill")
                                        .font(.system(size: 36))
                                        .opacity(currentIndex < imageFiles.count - 1 ? 0.8 : 0.3)
                                }
                                .accessibilityLabel("Next Image")
                                .disabled(currentIndex == imageFiles.count - 1)
                            }
                            .padding(.top, 12)
                        }
                    } else if let first = imageFiles.first, let data = first.fileData, let uiImage = UIImage(data: data) {
                        ScrollView {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFit()
                                .rotationEffect(.degrees(imageRotationDegrees))
                                .scaleEffect(imageScale)
                                .offset(imageOffset)
                                .gesture(
                                    SimultaneousGesture(
                                        MagnificationGesture()
                                            .onChanged { value in
                                                imageScale = value
                                            }
                                            .onEnded { _ in
                                                if imageScale < 1.0 { imageScale = 1.0 }
                                                if imageScale > 5.0 { imageScale = 5.0 }
                                                if imageScale == 1.0 { imageOffset = .zero }
                                            },
                                        DragGesture()
                                            .onChanged { value in
                                                if imageScale > 1.0 {
                                                    imageOffset = value.translation
                                                }
                                            }
                                            .onEnded { _ in
                                                if imageScale == 1.0 { imageOffset = .zero }
                                            }
                                    )
                                )
                        }
                    } else {
                        errorView(message: "The JPEG/PNG image could not be loaded.")
                    }
                } else {
                    errorView(message: "File type \(manualFile.fileType ?? String(localized: "Unknown")) is not supported.")
                }
            } else {
                errorView(message: "No data was stored for this file.")
            }
        }
        .navigationTitle(manualFile.fileName ?? String(localized: "File"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            // Toolbar with PDF and image actions (rotate)
            if manualFile.fileType?.lowercased() == UTType.pdf.preferredFilenameExtension {
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    Button(action: { rotatePDF(by: -90) }) {
                        Image(systemName: "rotate.left.fill")
                    }
                    .accessibilityLabel("Rotate Left")
                    Button(action: { rotatePDF(by: 90) }) {
                        Image(systemName: "rotate.right.fill")
                    }
                    .accessibilityLabel("Rotate Right")
                }
            } else if manualFile.fileType?.lowercased() == UTType.jpeg.preferredFilenameExtension ||
                      manualFile.fileType?.lowercased() == "jpg" ||
                      manualFile.fileType?.lowercased() == UTType.png.preferredFilenameExtension {
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    Button(action: { rotateImage(by: -90) }) {
                        Image(systemName: "rotate.left.fill")
                    }
                    .accessibilityLabel("Rotate Left")
                    Button(action: { rotateImage(by: 90) }) {
                        Image(systemName: "rotate.right.fill")
                    }
                    .accessibilityLabel("Rotate Right")
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                if let shareURL {
                    ShareLink(item: shareURL)
                }
            }
        }
        // Temporary copy of the shown file for sharing
        .task(id: currentIndex) {
            shareURL = try? FileExport.temporaryURL(for: displayedFile)
        }
    }

    // The file currently on screen (in a gallery, the selected image)
    private var displayedFile: ManualFile {
        imageFiles.count > 1 && imageFiles.indices.contains(currentIndex) ? imageFiles[currentIndex] : manualFile
    }
    
    // Error message shown when the file cannot be displayed
    @ViewBuilder
    private func errorView(message: LocalizedStringKey) -> some View {
        VStack(spacing: 15) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 70))
                .foregroundColor(.orange)
            Text("File Cannot Be Displayed")
                .font(.title2)
                .foregroundColor(.secondary)
            Text(message)
                .font(.callout)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
    }
    
    // Rotates the PDF by the given degrees and saves the change
    private func rotatePDF(by degrees: Int16) {
        var newRotation = manualFile.pdfRotationDegrees + degrees
        if newRotation >= 360 { newRotation -= 360 }
        if newRotation < 0 { newRotation += 360 }
        
        manualFile.pdfRotationDegrees = newRotation
        
        do {
            try viewContext.save()
        } catch {
            print("Failed to save PDF rotation: \(error.localizedDescription)")
        }
    }
    
    // Rotates the image by the given degrees and saves the change
    private func rotateImage(by degrees: Double) {
        var newRotation = imageRotationDegrees + degrees
        if newRotation >= 360 { newRotation -= 360 }
        if newRotation < 0 { newRotation += 360 }
        imageRotationDegrees = newRotation
        // Persist the value
        manualFile.setValue(Int16(newRotation), forKey: "imageRotationDegrees")
        do {
            try viewContext.save()
        } catch {
            print("Failed to save image rotation: \(error.localizedDescription)")
        }
    }
}

// PDFKitView shows a PDF with its rotation.
struct PDFKitView: UIViewRepresentable {
    @ObservedObject var manualFile: ManualFile
    
    func makeUIView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.translatesAutoresizingMaskIntoConstraints = false
        if let data = manualFile.fileData, let document = PDFDocument(data: data) {
            pdfView.document = document
            applyRotation(to: document, angle: manualFile.pdfRotationDegrees, forView: pdfView)
        }
        pdfView.autoScales = true
        pdfView.displayMode = .singlePageContinuous
        pdfView.displayDirection = .vertical
        pdfView.minScaleFactor = 0.25
        pdfView.maxScaleFactor = 5.0
        pdfView.backgroundColor = UIColor.systemBackground
        pdfView.isUserInteractionEnabled = true
        return pdfView
    }
    
    func updateUIView(_ pdfView: PDFView, context: Context) {
        // Updates the rotation or the document if the data has changed
        if let document = pdfView.document, manualFile.pdfRotationDegrees != pageRotation(of: document) {
             applyRotation(to: document, angle: manualFile.pdfRotationDegrees, forView: pdfView)
        } else if let data = manualFile.fileData, pdfView.document == nil || pdfView.document?.dataRepresentation() != data {
            if let newDocument = PDFDocument(data: data) {
                pdfView.document = newDocument
                applyRotation(to: newDocument, angle: manualFile.pdfRotationDegrees, forView: pdfView)
            }
        }
    }
    
    // Rotation of the document's first page
    private func pageRotation(of document: PDFDocument) -> Int16 {
        if let page = document.page(at: 0) {
            return Int16(page.rotation)
        }
        return 0
    }
    
    // Applies the rotation to all pages and restores the view state
    private func applyRotation(to document: PDFDocument, angle: Int16, forView pdfView: PDFView) {
        let currentPageIndex = pdfView.currentPage?.pageRef?.pageNumber ?? 1
        let currentScaleFactor = pdfView.scaleFactor
        
        for i in 0..<document.pageCount {
            if let page = document.page(at: i) {
                page.rotation = Int(angle)
            }
        }
        pdfView.layoutDocumentView()
        
        if document.pageCount > 0 {
            let pageToGo = (currentPageIndex > 0 && currentPageIndex <= document.pageCount) ? document.page(at: currentPageIndex - 1) : document.page(at: 0)
            if let targetPage = pageToGo {
                 pdfView.go(to: targetPage)
            }
            pdfView.scaleFactor = currentScaleFactor
        }
    }
}

#Preview {
    let context = PersistenceController.preview.container.viewContext
    
    let pdfManual = Manual(context: context)
    pdfManual.title = "Beispiel Manual"
    pdfManual.dateAdded = Date()
    
    let pdfFile = ManualFile(context: context)
    pdfFile.fileName = "Anleitung.pdf"
    pdfFile.fileType = "pdf"
    pdfFile.dateAdded = Date()
    pdfFile.fileData = Data()
    pdfFile.pdfRotationDegrees = 0
    
    let jpgFile = ManualFile(context: context)
    jpgFile.fileName = "Produktbild.jpeg"
    jpgFile.fileType = "jpeg"
    jpgFile.dateAdded = Date()
    jpgFile.fileData = Data()
    
    pdfManual.addToFiles(pdfFile)
    pdfManual.addToFiles(jpgFile)

    return NavigationView {
        ManualDisplayView(manual: pdfManual)
            .environment(\.managedObjectContext, context)
    }
} 
//
//  ManualDisplayView.swift
//  ManualShelf
//
//  Created by Christian Bram on 02.06.25.
//

import SwiftUI
import PDFKit // Für die Anzeige von PDF-Dateien
import UniformTypeIdentifiers // Für die Erkennung von Dateitypen

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
    @State private var displayedTags: [ManualTag] = []
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Tag-Bearbeitung
            Text("Tags")
                .font(.headline)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack {
                    ForEach(displayedTags, id: \.objectID) { tag in
                        HStack(spacing: 4) {
                            Text(tag.name ?? "")
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(colorForTag(tag))
                                .foregroundColor(.white)
                                .cornerRadius(12)
                            Button(action: { removeTag(tag) }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.white)
                            }
                        }
                        .padding(2)
                    }
                }
            }
            // Tag-Eingabefeld mit Autovervollständigung
            HStack {
                TextField("Tag hinzufügen...", text: $tagInput, onCommit: { addTagIfNeeded() })
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                Button("Hinzufügen") { addTagIfNeeded() }
                    .disabled(tagInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            if !tagInput.isEmpty {
                ForEach(allTags.filter { $0.name?.lowercased().contains(tagInput.lowercased()) == true && !displayedTags.contains($0) }, id: \.objectID) { tag in
                    Button(tag.name ?? "") {
                        addTag(tag)
                    }
                }
            }
            // Dateiliste wie gehabt
            List {
                let fileSet = manual.files as? Set<ManualFile> ?? []
                let files = fileSet.sorted { $0.dateAdded ?? Date.distantPast < $1.dateAdded ?? Date.distantPast }
                ForEach(files) { file in
                    NavigationLink(destination: FileDisplayView(manualFile: file)) {
                        HStack {
                            Image(systemName: file.fileType == UTType.pdf.preferredFilenameExtension ? "doc.text.fill" : "photo.fill")
                                .foregroundColor(.accentColor)
                            Text(file.fileName ?? "Unbenannte Datei")
                        }
                    }
                }
                .onDelete(perform: deleteFiles)
            }
            .listStyle(PlainListStyle())
        }
        .padding()
        .navigationTitle(manual.title ?? "Dateien")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    showingAddFilePicker = true
                }) {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingAddFilePicker) {
            DocumentPickerView { result in
                switch result {
                case .success(let (data, name, type)):
                    addFileToManual(data: data, name: name, type: type)
                case .failure(let error):
                    self.alertTitle = "Fehler beim Hinzufügen"
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
    
    // Liefert alle in diesem Manual verwendeten Tags (über alle Files)
    private var usedTags: [ManualTag] {
        let files = manual.files as? Set<ManualFile> ?? []
        let tags = files.flatMap { ($0.manualTags as? Set<ManualTag>) ?? [] }
        return Array(Set(tags)).sorted { ($0.name ?? "") < ($1.name ?? "") }
    }
    
    // Fügt eine neue Datei dem Manual hinzu und speichert sie im Core Data Kontext
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
            self.alertTitle = "Fehler beim Speichern"
            self.alertMessage = "Die neue Datei konnte nicht zum Manual hinzugefügt werden: \(error.localizedDescription)"
            self.showingAlert = true
        }
    }
    
    // Neue Funktion zum Löschen einzelner Dateien aus dem Manual
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
            self.alertTitle = "Fehler beim Löschen"
            self.alertMessage = "Die Datei konnte nicht entfernt werden: \(error.localizedDescription)"
            self.showingAlert = true
        }
    }
    
    // Tag hinzufügen (existierend oder neu)
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
                alertTitle = "Fehler beim Hinzufügen"
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
        do { try viewContext.save() } catch { print("Fehler beim Speichern: \(error)") }
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
            // Prüfe, ob der Tag noch irgendwo verwendet wird
            if (tag.manuals?.count ?? 0) == 0 {
                viewContext.delete(tag)
                try? viewContext.save()
            }
        } catch { print("Fehler beim Speichern: \(error)") }
        displayedTags = usedTags
    }
    
    // Farbenblindenfreundliche Farbpalette
    private let tagColors: [Color] = [
        Color(red: 0.00, green: 0.45, blue: 0.70), // Blau
        Color(red: 0.90, green: 0.63, blue: 0.00), // Orange
        Color(red: 0.34, green: 0.71, blue: 0.91), // Türkis
        Color(red: 0.94, green: 0.89, blue: 0.26), // Gelb
        Color(red: 0.27, green: 0.62, blue: 0.28), // Grün
        Color(red: 0.80, green: 0.48, blue: 0.74), // Pink
        Color(red: 0.55, green: 0.34, blue: 0.64), // Violett
        Color(red: 0.27, green: 0.27, blue: 0.27)  // Dunkelgrau
    ]
    private func colorForTag(_ tag: ManualTag) -> Color {
        guard let name = tag.name else { return tagColors[0] }
        let hash = abs(name.hashValue)
        return tagColors[hash % tagColors.count]
    }
}

// FileDisplayView zeigt eine einzelne Datei (PDF oder Bild) an und ermöglicht ggf. das Drehen von PDFs.
struct FileDisplayView: View {
    @ObservedObject var manualFile: ManualFile
    @Environment(\.managedObjectContext) private var viewContext

    // State für die Galerie
    @State private var currentIndex: Int = 0
    @State private var imageRotationDegrees: Double = 0 // NEU: Bildrotation
    @State private var imageScale: CGFloat = 1.0 // NEU: Zoom
    @State private var imageOffset: CGSize = .zero // NEU: Verschiebung
    private var imageFiles: [ManualFile] = []
    
    // Initializer, um imageFiles und currentIndex zu setzen
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
        // Bildrotation initial aus CoreData laden (für Einzelbild-Ansicht)
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
                                            .rotationEffect(.degrees(idx == currentIndex ? imageRotationDegrees : 0)) // NEU
                                            .scaleEffect(idx == currentIndex ? imageScale : 1.0) // NEU
                                            .offset(idx == currentIndex ? imageOffset : .zero) // NEU
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
                                        errorView(message: "Das Bild konnte nicht geladen werden.")
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
                                .disabled(currentIndex == 0)
                                Text("\(currentIndex + 1) von \(imageFiles.count)")
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
                                .disabled(currentIndex == imageFiles.count - 1)
                            }
                            .padding(.top, 12)
                        }
                    } else if let first = imageFiles.first, let data = first.fileData, let uiImage = UIImage(data: data) {
                        ScrollView {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFit()
                                .rotationEffect(.degrees(imageRotationDegrees)) // NEU
                                .scaleEffect(imageScale) // NEU
                                .offset(imageOffset) // NEU
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
                        errorView(message: "Das JPEG-/PNG-Bild konnte nicht geladen werden.")
                    }
                } else {
                    errorView(message: "Dateityp \(manualFile.fileType ?? "Unbekannt") wird nicht unterstützt.")
                }
            } else {
                errorView(message: "Für diese Datei wurden keine Daten gespeichert.")
            }
        }
        .navigationTitle(manualFile.fileName ?? "Datei")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            // Toolbar für PDF- und Bild-spezifische Aktionen (Drehen)
            if manualFile.fileType?.lowercased() == UTType.pdf.preferredFilenameExtension {
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    Button(action: { rotatePDF(by: -90) }) {
                        Image(systemName: "rotate.left.fill")
                    }
                    Button(action: { rotatePDF(by: 90) }) {
                        Image(systemName: "rotate.right.fill")
                    }
                }
            } else if manualFile.fileType?.lowercased() == UTType.jpeg.preferredFilenameExtension ||
                      manualFile.fileType?.lowercased() == "jpg" ||
                      manualFile.fileType?.lowercased() == UTType.png.preferredFilenameExtension {
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    Button(action: { rotateImage(by: -90) }) {
                        Image(systemName: "rotate.left.fill")
                    }
                    Button(action: { rotateImage(by: 90) }) {
                        Image(systemName: "rotate.right.fill")
                    }
                }
            }
        }
    }
    
    // Zeigt eine Fehlermeldung an, wenn die Datei nicht angezeigt werden kann
    @ViewBuilder
    private func errorView(message: String) -> some View {
        VStack(spacing: 15) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 70))
                .foregroundColor(.orange)
            Text("Datei nicht darstellbar")
                .font(.title2)
                .foregroundColor(.secondary)
            Text(message)
                .font(.callout)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
    }
    
    // Dreht die PDF-Datei um die angegebene Gradzahl und speichert die Änderung
    private func rotatePDF(by degrees: Int16) {
        var newRotation = manualFile.pdfRotationDegrees + degrees
        if newRotation >= 360 { newRotation -= 360 }
        if newRotation < 0 { newRotation += 360 }
        
        manualFile.pdfRotationDegrees = newRotation
        
        do {
            try viewContext.save()
        } catch {
            print("Fehler beim Speichern der PDF-Drehung: \(error.localizedDescription)")
        }
    }
    
    // NEU: Funktion zum Drehen des Bildes
    private func rotateImage(by degrees: Double) {
        var newRotation = imageRotationDegrees + degrees
        if newRotation >= 360 { newRotation -= 360 }
        if newRotation < 0 { newRotation += 360 }
        imageRotationDegrees = newRotation
        // Wert persistent speichern
        manualFile.setValue(Int16(newRotation), forKey: "imageRotationDegrees")
        do {
            try viewContext.save()
        } catch {
            print("Fehler beim Speichern der Bild-Drehung: \(error.localizedDescription)")
        }
    }
}

// PDFKitView stellt eine PDF-Datei mit Rotation dar.
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
        // Aktualisiert die Rotation oder das Dokument, falls sich die Daten geändert haben
        if let document = pdfView.document, manualFile.pdfRotationDegrees != pageRotation(of: document) {
             applyRotation(to: document, angle: manualFile.pdfRotationDegrees, forView: pdfView)
        } else if let data = manualFile.fileData, pdfView.document == nil || pdfView.document?.dataRepresentation() != data {
            if let newDocument = PDFDocument(data: data) {
                pdfView.document = newDocument
                applyRotation(to: newDocument, angle: manualFile.pdfRotationDegrees, forView: pdfView)
            }
        }
    }
    
    // Gibt die Rotation der ersten Seite des Dokuments zurück
    private func pageRotation(of document: PDFDocument) -> Int16 {
        if let page = document.page(at: 0) {
            return Int16(page.rotation)
        }
        return 0
    }
    
    // Wendet die gewünschte Rotation auf alle Seiten des Dokuments an und stellt die Ansicht wieder her
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
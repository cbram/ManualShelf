//
//  AddManualView.swift
//  ManualShelf
//
//  Created by Christian Bram on 02.06.25.
//

import SwiftUI
import CoreData
import UniformTypeIdentifiers

struct AddManualView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.presentationMode) var presentationMode
    
    @State private var title = ""
    @State private var showingDocumentPicker = false
    @State private var selectedFileData: Data?
    @State private var selectedFileName = ""
    @State private var selectedFileType: UTType?
    
    @State private var showingAlert = false
    @State private var alertTitle = "Fehler"
    @State private var alertMessage = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Titel des Manuals")
                        .font(.headline)
                    
                    TextField("z.B. iPhone 15 Bedienungsanleitung", text: $title)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Manual-Datei (PDF oder JPEG)")
                        .font(.headline)
                    
                    Button(action: { showingDocumentPicker = true }) {
                        HStack {
                            Image(systemName: selectedFileData == nil ? "doc.badge.plus" : "doc.text.fill")
                                .foregroundColor(selectedFileData == nil ? .accentColor : .green)
                                .font(.title2)
                            
                            Text(selectedFileName.isEmpty ? "Datei auswählen (PDF, JPEG)" : selectedFileName)
                                .foregroundColor(selectedFileName.isEmpty ? .secondary : .primary)
                                .lineLimit(1)
                                .truncationMode(.middle)
                            
                            Spacer()
                            
                            if selectedFileData != nil {
                                Button(action: clearFileSelection) {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.gray)
                                        .font(.title2)
                                }
                                .padding(.leading, 5)
                            } else {
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                    }
                    .foregroundColor(.primary)
                }
                
                Spacer()
                
                Button(action: saveManual) {
                    Text("Manual hinzufügen")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(canSave ? Color.blue : Color.gray)
                        .cornerRadius(10)
                }
                .disabled(!canSave)
            }
            .padding()
            .navigationTitle("Neues Manual")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Abbrechen") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingDocumentPicker) {
                DocumentPicker(selectedFileData: $selectedFileData, 
                               selectedFileName: $selectedFileName,
                               selectedFileType: $selectedFileType,
                               onError: { errorMsg in
                                    self.alertTitle = "Fehler beim Laden der Datei"
                                    self.alertMessage = errorMsg
                                    self.showingAlert = true
                               })
            }
            .alert(alertTitle, isPresented: $showingAlert) {
                Button("OK") { }
            } message: {
                Text(alertMessage)
            }
        }
    }
    
    private var canSave: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && 
        selectedFileData != nil &&
        selectedFileType != nil
    }
    
    private func clearFileSelection() {
        selectedFileData = nil
        selectedFileName = ""
        selectedFileType = nil
    }
    
    private func saveManual() {
        guard let fileData = selectedFileData, let fileType = selectedFileType else { 
            self.alertTitle = "Fehler beim Speichern"
            self.alertMessage = "Keine Datei oder Dateityp zum Speichern vorhanden."
            self.showingAlert = true
            return
        }
        
        let manual = Manual(context: viewContext)
        manual.title = title.trimmingCharacters(in: .whitespacesAndNewlines)
        manual.fileName = selectedFileName
        manual.dateAdded = Date()
        manual.fileData = fileData
        manual.fileType = fileType.preferredFilenameExtension
        manual.pdfRotationDegrees = 0 // Standard-Rotation für neue Manuals
        
        do {
            try viewContext.save()
            presentationMode.wrappedValue.dismiss()
        } catch {
            self.alertTitle = "Fehler beim Speichern"
            self.alertMessage = "Das Manual konnte nicht gespeichert werden: \(error.localizedDescription)"
            self.showingAlert = true
        }
    }
}

struct DocumentPicker: UIViewControllerRepresentable {
    @Binding var selectedFileData: Data?
    @Binding var selectedFileName: String
    @Binding var selectedFileType: UTType?
    var onError: ((String) -> Void)?
    @Environment(\.presentationMode) var presentationMode
    
    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [UTType.pdf, UTType.jpeg])
        picker.delegate = context.coordinator
        picker.allowsMultipleSelection = false
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIDocumentPickerDelegate {
        let parent: DocumentPicker
        
        init(_ parent: DocumentPicker) {
            self.parent = parent
        }
        
        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            guard let url = urls.first else { return }
            
            let typeIdentifier = try? url.resourceValues(forKeys: [.typeIdentifierKey]).typeIdentifier
            let ext = url.pathExtension.lowercased()
            print("[DEBUG] typeIdentifier: \(String(describing: typeIdentifier)), extension: \(ext)")
            
            var utType: UTType? = nil
            if let typeIdentifier = typeIdentifier, let detectedUTType = UTType(typeIdentifier) {
                utType = detectedUTType
            } else if ext == "pdf" {
                utType = UTType.pdf
            } else if ext == "jpeg" || ext == "jpg" {
                utType = UTType.jpeg
            }
            
            guard let validUTType = utType else {
                DispatchQueue.main.async {
                    self.parent.selectedFileData = nil
                    self.parent.selectedFileName = ""
                    self.parent.selectedFileType = nil
                    let userMessage = "Der Dateityp konnte nicht bestimmt werden (keine typeIdentifier und keine bekannte Endung)."
                    self.parent.onError?(userMessage)
                }
                return
            }

            guard [UTType.pdf, UTType.jpeg].contains(validUTType) else {
                DispatchQueue.main.async {
                    self.parent.selectedFileData = nil
                    self.parent.selectedFileName = ""
                    self.parent.selectedFileType = nil
                    let userMessage = "Nicht unterstützter Dateityp: \(validUTType.localizedDescription ?? "Unbekannt")"
                    self.parent.onError?(userMessage)
                }
                return
            }
            
            var accessError: Error?
            let didStartAccessing = url.startAccessingSecurityScopedResource()
            defer { if didStartAccessing { url.stopAccessingSecurityScopedResource() } }
            
            if didStartAccessing {
                do {
                    let data = try Data(contentsOf: url)
                    DispatchQueue.main.async {
                        self.parent.selectedFileData = data
                        self.parent.selectedFileName = url.lastPathComponent
                        self.parent.selectedFileType = validUTType
                    }
                } catch {
                    accessError = error
                }
            } else {
                accessError = NSError(domain: NSCocoaErrorDomain, code: NSFileReadNoPermissionError, userInfo: [NSLocalizedDescriptionKey: "Keine Berechtigung zum Lesen der Datei."])
            }
            
            if let error = accessError {
                DispatchQueue.main.async {
                    self.parent.selectedFileData = nil
                    self.parent.selectedFileName = ""
                    self.parent.selectedFileType = nil
                    let userMessage = "Die ausgewählte Datei konnte nicht geladen werden. (\(error.localizedDescription))"
                    self.parent.onError?(userMessage)
                }
            }
        }
        
        func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        }
    }
}

#Preview {
    AddManualView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
} 
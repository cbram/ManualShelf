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
    @State private var selectedPDFData: Data?
    @State private var selectedFileName = ""
    
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
                    Text("PDF-Datei")
                        .font(.headline)
                    
                    Button(action: { showingDocumentPicker = true }) {
                        HStack {
                            Image(systemName: selectedPDFData == nil ? "doc.badge.plus" : "doc.text.fill")
                                .foregroundColor(selectedPDFData == nil ? .accentColor : .green)
                                .font(.title2)
                            
                            Text(selectedFileName.isEmpty ? "PDF-Datei auswählen" : selectedFileName)
                                .foregroundColor(selectedFileName.isEmpty ? .secondary : .primary)
                                .lineLimit(1)
                                .truncationMode(.middle)
                            
                            Spacer()
                            
                            if selectedPDFData != nil {
                                Button(action: clearPDFSelection) {
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
                DocumentPicker(selectedPDFData: $selectedPDFData, 
                               selectedFileName: $selectedFileName,
                               onError: { errorMsg in
                                    self.alertTitle = "Fehler beim Laden der PDF"
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
        selectedPDFData != nil
    }
    
    private func clearPDFSelection() {
        selectedPDFData = nil
        selectedFileName = ""
    }
    
    private func saveManual() {
        guard let pdfData = selectedPDFData else { 
            self.alertTitle = "Fehler beim Speichern"
            self.alertMessage = "Keine PDF-Daten zum Speichern vorhanden."
            self.showingAlert = true
            return
        }
        
        let manual = Manual(context: viewContext)
        manual.title = title.trimmingCharacters(in: .whitespacesAndNewlines)
        manual.fileName = selectedFileName
        manual.dateAdded = Date()
        manual.fileData = pdfData
        
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
    @Binding var selectedPDFData: Data?
    @Binding var selectedFileName: String
    var onError: ((String) -> Void)?
    @Environment(\.presentationMode) var presentationMode
    
    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [UTType.pdf])
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
            
            var accessError: Error?
            let didStartAccessing = url.startAccessingSecurityScopedResource()
            defer { if didStartAccessing { url.stopAccessingSecurityScopedResource() } }
            
            if didStartAccessing {
                do {
                    let data = try Data(contentsOf: url)
                    DispatchQueue.main.async {
                        self.parent.selectedPDFData = data
                        self.parent.selectedFileName = url.lastPathComponent
                    }
                } catch {
                    accessError = error
                }
            } else {
                accessError = NSError(domain: NSCocoaErrorDomain, code: NSFileReadNoPermissionError, userInfo: [NSLocalizedDescriptionKey: "Keine Berechtigung zum Lesen der Datei."])
            }
            
            if let error = accessError {
                DispatchQueue.main.async {
                    self.parent.selectedPDFData = nil
                    self.parent.selectedFileName = ""
                    let userMessage = "Die ausgewählte PDF-Datei konnte nicht geladen werden. (\(error.localizedDescription))"
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
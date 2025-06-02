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
                            Image(systemName: "doc.badge.plus")
                            Text(selectedFileName.isEmpty ? "PDF-Datei auswählen" : selectedFileName)
                                .foregroundColor(selectedFileName.isEmpty ? .secondary : .primary)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
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
                DocumentPicker(selectedPDFData: $selectedPDFData, selectedFileName: $selectedFileName)
            }
            .alert("Fehler", isPresented: $showingAlert) {
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
    
    private func saveManual() {
        guard let pdfData = selectedPDFData else { return }
        
        let manual = Manual(context: viewContext)
        manual.title = title.trimmingCharacters(in: .whitespacesAndNewlines)
        manual.fileName = selectedFileName
        manual.dateAdded = Date()
        manual.fileData = pdfData
        
        do {
            try viewContext.save()
            presentationMode.wrappedValue.dismiss()
        } catch {
            alertMessage = "Fehler beim Speichern: \(error.localizedDescription)"
            showingAlert = true
        }
    }
}

struct DocumentPicker: UIViewControllerRepresentable {
    @Binding var selectedPDFData: Data?
    @Binding var selectedFileName: String
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
            
            if url.startAccessingSecurityScopedResource() {
                defer { url.stopAccessingSecurityScopedResource() }
                
                do {
                    let data = try Data(contentsOf: url)
                    DispatchQueue.main.async {
                        self.parent.selectedPDFData = data
                        self.parent.selectedFileName = url.lastPathComponent
                        self.parent.presentationMode.wrappedValue.dismiss()
                    }
                } catch {
                    print("Fehler beim Laden der PDF: \(error)")
                }
            }
        }
        
        func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
}

#Preview {
    AddManualView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
} 
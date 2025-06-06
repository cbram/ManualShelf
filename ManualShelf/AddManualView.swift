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
                DocumentPickerView { result in
                    switch result {
                    case .success(let (data, name, type)):
                        self.selectedFileData = data
                        self.selectedFileName = name
                        self.selectedFileType = type
                    case .failure(let error):
                        self.alertTitle = "Fehler beim Laden der Datei"
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
        manual.dateAdded = Date() // Das Hinzufügedatum des Manuals selbst

        let manualFile = ManualFile(context: viewContext)
        manualFile.fileName = selectedFileName
        manualFile.fileData = fileData
        manualFile.fileType = fileType.preferredFilenameExtension
        manualFile.pdfRotationDegrees = 0 // Standard-Rotation für neue Dateien
        manualFile.dateAdded = Date() // Hinzufügedatum der Datei
        
        manual.addToFiles(manualFile) // Verknüpft die Datei mit dem Manual
        
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

#Preview {
    AddManualView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
} 
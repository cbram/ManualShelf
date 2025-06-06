//
//  AddManualView.swift
//  ManualShelf
//
//  Created by Christian Bram on 02.06.25.
//

import SwiftUI
import CoreData
import UniformTypeIdentifiers

private struct PickedFile: Identifiable {
    let id = UUID()
    let data: Data
    let name: String
    let type: UTType
}

struct AddManualView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.presentationMode) private var presentationMode
    
    @State private var title: String = ""
    @State private var pickedFiles: [PickedFile] = []
    
    @State private var showingDocumentPicker = false
    @State private var showingAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Eingabefeld für den Titel des Manuals
                VStack(alignment: .leading, spacing: 8) {
                    Text("Titel des Manuals")
                        .font(.headline)
                    
                    TextField("z.B. iPhone 15 Bedienungsanleitung", text: $title)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                
                // Bereich zur Dateiauswahl und Anzeige der gewählten Dateien
                VStack(alignment: .leading, spacing: 8) {
                    Text("Dateien")
                        .font(.headline)
                    
                    VStack {
                        if !pickedFiles.isEmpty {
                            ForEach(pickedFiles) { file in
                                HStack {
                                    Image(systemName: file.type == .pdf ? "doc.text.fill" : "photo.fill")
                                        .foregroundColor(.green)
                                    Text(file.name)
                                        .lineLimit(1)
                                        .truncationMode(.middle)
                                    Spacer()
                                    Button(action: { removeFile(file) }) {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundColor(.gray)
                                    }
                                }
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(8)
                            }
                        }
                        
                        // Button zum Hinzufügen weiterer Dateien
                        Button(action: { showingDocumentPicker = true }) {
                            HStack {
                                Image(systemName: "doc.badge.plus")
                                    .foregroundColor(.accentColor)
                                Text("Weitere Datei hinzufügen...")
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
                }
                
                Spacer()
                
                // Button zum Speichern des Manuals
                Button(action: saveManual) {
                    Text("Manual speichern")
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
                    // Schließt die View ohne zu speichern
                    Button("Abbrechen") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
            // Öffnet den Dokumenten-Picker
            .sheet(isPresented: $showingDocumentPicker) {
                DocumentPickerView { result in
                    switch result {
                    case .success(let (data, name, type)):
                        let newFile = PickedFile(data: data, name: name, type: type)
                        pickedFiles.append(newFile)
                    case .failure(let error):
                        self.alertTitle = "Fehler beim Laden"
                        self.alertMessage = error.localizedDescription
                        self.showingAlert = true
                    }
                }
            }
            // Zeigt Fehler-Alerts an
            .alert(alertTitle, isPresented: $showingAlert) {
                Button("OK") { }
            } message: {
                Text(alertMessage)
            }
        }
    }
    
    // Validiert, ob das Manual gespeichert werden kann
    private var canSave: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !pickedFiles.isEmpty
    }
    
    // Entfernt eine Datei aus der Auswahl
    private func removeFile(_ file: PickedFile) {
        pickedFiles.removeAll { $0.id == file.id }
    }
    
    // Speichert das neue Manual und die zugehörigen Dateien im Core Data Kontext
    private func saveManual() {
        guard canSave else {
            self.alertTitle = "Fehler beim Speichern"
            self.alertMessage = "Bitte geben Sie einen Titel an und wählen Sie mindestens eine Datei aus."
            self.showingAlert = true
            return
        }
        
        let manual = Manual(context: viewContext)
        manual.title = title.trimmingCharacters(in: .whitespacesAndNewlines)
        manual.dateAdded = Date()

        for file in pickedFiles {
            let manualFile = ManualFile(context: viewContext)
            manualFile.fileName = file.name
            manualFile.fileData = file.data
            manualFile.fileType = file.type.preferredFilenameExtension
            manualFile.pdfRotationDegrees = 0
            manualFile.dateAdded = Date()
            manual.addToFiles(manualFile)
        }
        
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
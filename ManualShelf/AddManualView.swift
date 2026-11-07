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
    @State private var showingURLDownload = false
    @State private var showingAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    
    // Tagging state
    @FetchRequest(
        entity: ManualTag.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \ManualTag.name, ascending: true)]
    ) var allTags: FetchedResults<ManualTag>
    @State private var tagInput: String = ""
    @State private var selectedTags: [ManualTag] = []
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Title input
                VStack(alignment: .leading, spacing: 8) {
                    Text("Manual Title")
                        .font(.headline)
                    
                    TextField("e.g. iPhone 15 User Guide", text: $title)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                
                // Tag selection
                VStack(alignment: .leading, spacing: 8) {
                    Text("Tags")
                        .font(.headline)
                    // Chips for the selected tags
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack {
                            ForEach(selectedTags, id: \.self) { tag in
                                HStack(spacing: 4) {
                                    Text(tag.name ?? "")
                                    Button(action: { selectedTags.removeAll { $0 == tag } }) {
                                        Image(systemName: "xmark.circle.fill")
                                    }
                                    .accessibilityLabel("Remove tag \(tag.name ?? "")")
                                }
                                .padding(6)
                                .background(Color.gray.opacity(0.2))
                                .cornerRadius(12)
                            }
                        }
                    }
                    // Tag input with autocompletion
                    TextField("Add tag...", text: $tagInput, onCommit: { addTagIfNeeded() })
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    // Suggestions
                    if !tagInput.isEmpty {
                        ForEach(allTags.filter { $0.name?.lowercased().contains(tagInput.lowercased()) == true && !selectedTags.contains($0) }, id: \.self) { tag in
                            Button(tag.name ?? "") {
                                selectedTags.append(tag)
                                tagInput = ""
                            }
                        }
                    }
                }
                
                // File picking and list of picked files
                VStack(alignment: .leading, spacing: 8) {
                    Text("Files")
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
                                    .accessibilityLabel("Remove file \(file.name)")
                                }
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(8)
                            }
                        }
                        
                        // Button to add more files
                        Button(action: { showingDocumentPicker = true }) {
                            HStack {
                                Image(systemName: "doc.badge.plus")
                                    .foregroundColor(.accentColor)
                                Text("Add another file...")
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.secondary)
                            }
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                        }
                        .foregroundColor(.primary)

                        // Button to load a file from a web address
                        Button(action: { showingURLDownload = true }) {
                            HStack {
                                Image(systemName: "link")
                                    .foregroundColor(.accentColor)
                                Text("Load from URL...")
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.secondary)
                            }
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                        }
                        .foregroundColor(.primary)
                        .sheet(isPresented: $showingURLDownload) {
                            URLDownloadView { data, name, type in
                                addPickedFile(data: data, name: name, type: type)
                            }
                        }
                    }
                }
                
                Spacer()
                
                // Button to save the manual
                Button(action: saveManual) {
                    Text("Save Manual")
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
            .navigationTitle("New Manual")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    // Closes the view without saving
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
            // Opens the document picker
            .sheet(isPresented: $showingDocumentPicker) {
                DocumentPickerView { result in
                    switch result {
                    case .success(let (data, name, type)):
                        addPickedFile(data: data, name: name, type: type)
                    case .failure(let error):
                        self.alertTitle = String(localized: "Error Loading")
                        self.alertMessage = error.localizedDescription
                        self.showingAlert = true
                    }
                }
            }
            // Shows error alerts
            .alert(alertTitle, isPresented: $showingAlert) {
                Button("OK") { }
            } message: {
                Text(alertMessage)
            }
        }
    }
    
    // Whether the manual can be saved
    private var canSave: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !pickedFiles.isEmpty
    }
    
    // Adds a picked or downloaded file and suggests the title from the first file
    private func addPickedFile(data: Data, name: String, type: UTType) {
        title = ManualTitleSuggestion.title(current: title, addedFileName: name, isFirstFile: pickedFiles.isEmpty)
        pickedFiles.append(PickedFile(data: data, name: name, type: type))
    }

    // Removes a file from the selection
    private func removeFile(_ file: PickedFile) {
        pickedFiles.removeAll { $0.id == file.id }
    }
    
    // Saves the new manual and its files in the Core Data context
    private func saveManual() {
        guard canSave else {
            self.alertTitle = String(localized: "Error Saving")
            self.alertMessage = String(localized: "Please enter a title and select at least one file.")
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
            // Assign tags
            manualFile.manualTags = NSSet(array: selectedTags)
            manual.addToFiles(manualFile)
        }
        
        do {
            try viewContext.save()
            presentationMode.wrappedValue.dismiss()
        } catch {
            self.alertTitle = String(localized: "Error Saving")
            self.alertMessage = String(localized: "The manual could not be saved: \(error.localizedDescription)")
            self.showingAlert = true
        }
    }
    
    // Adds the typed tag, reusing an existing one with the same name
    private func addTagIfNeeded() {
        let trimmed = tagInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        if let existing = allTags.first(where: { $0.name?.lowercased() == trimmed.lowercased() }) {
            if !selectedTags.contains(existing) {
                selectedTags.append(existing)
            }
        } else {
            let newTag = ManualTag(context: viewContext)
            newTag.name = trimmed
            selectedTags.append(newTag)
            try? viewContext.save()
        }
        tagInput = ""
    }
}

#Preview {
    AddManualView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
} 
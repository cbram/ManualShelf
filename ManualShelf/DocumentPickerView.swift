import SwiftUI
import UniformTypeIdentifiers

struct DocumentPickerView: UIViewControllerRepresentable {
    var onFilePicked: (Result<(Data, String, UTType), Error>) -> Void
    
    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        // Initialisiert den Dokumenten-Picker für PDF- und Bilddateien
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [UTType.pdf, UTType.jpeg, UTType.png])
        picker.delegate = context.coordinator
        picker.allowsMultipleSelection = false
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIDocumentPickerDelegate {
        let parent: DocumentPickerView
        
        init(_ parent: DocumentPickerView) {
            self.parent = parent
        }
        
        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            guard let url = urls.first else {
                parent.onFilePicked(.failure(PickerError.noFileSelected))
                return
            }
            
            // Ermittle den UTType, mit Fallback auf die Dateiendung
            var utType: UTType?
            if let typeIdentifier = try? url.resourceValues(forKeys: [.typeIdentifierKey]).typeIdentifier,
               let detectedUTType = UTType(typeIdentifier) {
                utType = detectedUTType
            } else {
                let ext = url.pathExtension.lowercased()
                if ext == "pdf" {
                    utType = UTType.pdf
                } else if ext == "jpeg" || ext == "jpg" {
                    utType = UTType.jpeg
                } else if ext == "png" {
                    utType = UTType.png
                }
            }

            // Unterstützt nur PDF, JPEG und PNG
            guard let validUTType = utType, [UTType.pdf, UTType.jpeg, UTType.png].contains(validUTType) else {
                parent.onFilePicked(.failure(PickerError.unsupportedFileType))
                return
            }
            
            // Greife auf die Datei zu (Security Scoped Resource)
            let didStartAccessing = url.startAccessingSecurityScopedResource()
            defer { if didStartAccessing { url.stopAccessingSecurityScopedResource() } }
            
            do {
                let data = try Data(contentsOf: url)
                parent.onFilePicked(.success((data, url.lastPathComponent, validUTType)))
            } catch {
                parent.onFilePicked(.failure(error))
            }
        }
        
        func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
            // Optional: Ein spezieller Error für den Abbruch-Fall
            // parent.onFilePicked(.failure(PickerError.cancelled))
        }
    }
    
    // Fehler, die beim Auswählen einer Datei auftreten können
    enum PickerError: Error, LocalizedError {
        case noFileSelected
        case unsupportedFileType
        case cancelled
        
        var errorDescription: String? {
            switch self {
            case .noFileSelected: return "Es wurde keine Datei ausgewählt."
            case .unsupportedFileType: return "Dieser Dateityp wird nicht unterstützt."
            case .cancelled: return "Die Auswahl wurde abgebrochen."
            }
        }
    }
} 
import SwiftUI
import UniformTypeIdentifiers

struct DocumentPickerView: UIViewControllerRepresentable {
    var onFilePicked: (Result<(Data, String, UTType), Error>) -> Void
    
    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        // Sets up the document picker for PDF and image files
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
            
            // Determine the UTType, falling back to the file extension
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

            // Supports PDF, JPEG and PNG only
            guard let validUTType = utType, [UTType.pdf, UTType.jpeg, UTType.png].contains(validUTType) else {
                parent.onFilePicked(.failure(PickerError.unsupportedFileType))
                return
            }
            
            // Access the file (security-scoped resource)
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
            // Optional: a dedicated error for cancellation
            // parent.onFilePicked(.failure(PickerError.cancelled))
        }
    }
    
    // Errors that can occur while picking a file
    enum PickerError: Error, LocalizedError {
        case noFileSelected
        case unsupportedFileType
        case cancelled
        
        var errorDescription: String? {
            switch self {
            case .noFileSelected: return String(localized: "No file was selected.")
            case .unsupportedFileType: return String(localized: "This file type is not supported.")
            case .cancelled: return String(localized: "The selection was cancelled.")
            }
        }
    }
} 
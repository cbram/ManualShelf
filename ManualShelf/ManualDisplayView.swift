//
//  ManualDisplayView.swift
//  ManualShelf
//
//  Created by Christian Bram on 02.06.25.
//

import SwiftUI
import PDFKit // Bleibt für PDF-Anzeige
import UniformTypeIdentifiers // Für UTType-Konstanten

struct ManualDisplayView: View { // Umbenannt von PDFViewerView
    @ObservedObject var manual: Manual
    @Environment(\.managedObjectContext) private var viewContext
    
    // pdfRotationDegrees wird nur für PDFs verwendet.
    // Die Toolbar zum Rotieren wird auch nur für PDFs angezeigt.

    var body: some View {
        Group {
            if let fileData = manual.fileData, !fileData.isEmpty {
                // Überprüfe den fileType, der als String (z.B. "pdf", "jpeg") gespeichert ist
                if manual.fileType?.lowercased() == UTType.pdf.preferredFilenameExtension {
                    PDFKitView(data: fileData, rotationAngle: manual.pdfRotationDegrees)
                } else if manual.fileType?.lowercased() == UTType.jpeg.preferredFilenameExtension || manual.fileType?.lowercased() == "jpg" {
                    // Für JPEG eine Image View verwenden
                    if let uiImage = UIImage(data: fileData) {
                        ScrollView { // Ermöglicht Scrollen, falls das Bild größer als der Bildschirm ist
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFit()
                        }
                    } else {
                        errorView(message: "Das JPEG-Bild konnte nicht geladen werden.")
                    }
                } else {
                    // Fallback, falls der Dateityp unbekannt ist oder nicht unterstützt wird
                    errorView(message: "Dateityp \"\(manual.fileType ?? "Unbekannt")\" wird nicht unterstützt.")
                }
            } else {
                // Wenn keine fileData vorhanden sind
                errorView(message: "Für dieses Manual wurden keine Dateidaten gespeichert.")
            }
        }
        .navigationTitle(manual.title ?? "Manual")
        .navigationBarTitleDisplayMode(.inline)
        // .edgesIgnoringSafeArea(.bottom) // Ggf. nur für PDFKitView sinnvoll, für Images prüfen
        .toolbar {
            // Toolbar-Items nur anzeigen, wenn es ein PDF ist
            if manual.fileType?.lowercased() == UTType.pdf.preferredFilenameExtension {
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    Button(action: { rotatePDF(by: -90) }) {
                        Image(systemName: "rotate.left.fill")
                    }
                    Button(action: { rotatePDF(by: 90) }) {
                        Image(systemName: "rotate.right.fill")
                    }
                }
            }
        }
    }
    
    // Hilfsfunktion für die Fehleransicht
    @ViewBuilder
    private func errorView(message: String) -> some View {
        VStack(spacing: 15) {
            Image(systemName: "exclamationmark.triangle.fill") // Allgemeineres Fehlersymbol
                .font(.system(size: 70))
                .foregroundColor(.orange) // Auffälligere Farbe für Fehler
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
    
    private func rotatePDF(by degrees: Int16) {
        // Diese Funktion bleibt unverändert, wird aber nur für PDFs aufgerufen
        var newRotation = manual.pdfRotationDegrees + degrees
        if newRotation >= 360 { newRotation -= 360 }
        if newRotation < 0 { newRotation += 360 }
        
        manual.pdfRotationDegrees = newRotation
        
        do {
            try viewContext.save()
        } catch {
            print("Fehler beim Speichern der PDF-Drehung: \(error.localizedDescription)")
            // Hier könnte man dem Benutzer eine Fehlermeldung anzeigen
        }
    }
}

// PDFKitView bleibt wie es ist, da es nur für PDFs verwendet wird.
// Es muss nicht nach ManualDisplayView.swift verschoben werden, wenn es nur hier verwendet wird,
// aber der Übersichtlichkeit halber könnte man es tun oder als private struct definieren.
// Fürs Erste belasse ich es hier, um den Diff klein zu halten.
struct PDFKitView: UIViewRepresentable {
    let data: Data
    let rotationAngle: Int16
    
    func makeUIView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.translatesAutoresizingMaskIntoConstraints = false
        if let document = PDFDocument(data: data) {
            pdfView.document = document
            applyRotation(to: document, angle: rotationAngle, forView: pdfView)
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
        if let document = pdfView.document {
            applyRotation(to: document, angle: rotationAngle, forView: pdfView)
        } else if let newDocumentData = PDFDocument(data: data) {
            pdfView.document = newDocumentData
            applyRotation(to: newDocumentData, angle: rotationAngle, forView: pdfView)
        }
    }
    
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
        // pdfView.autoScales = true // Kann dazu führen, dass die Skalierung zurückgesetzt wird. Testen.
    }
}

// Preview muss angepasst werden, um beide Fälle zu testen (PDF und JPEG)
#Preview {
    let context = PersistenceController.preview.container.viewContext
    
    // PDF Beispiel
    let pdfManual = Manual(context: context)
    pdfManual.title = "Beispiel PDF Manual"
    pdfManual.fileName = "beispiel.pdf"
    pdfManual.fileType = "pdf"
    pdfManual.dateAdded = Date()
    pdfManual.fileData = Data() // Leere Daten für Preview
    pdfManual.pdfRotationDegrees = 0

    return NavigationView {
        ManualDisplayView(manual: pdfManual)
            .environment(\.managedObjectContext, context)
    }
} 
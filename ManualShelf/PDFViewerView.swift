//
//  PDFViewerView.swift
//  ManualShelf
//
//  Created by Christian Bram on 02.06.25.
//

import SwiftUI
import PDFKit

struct PDFViewerView: View {
    let manual: Manual
    
    var body: some View {
        PDFKitView(data: manual.fileData ?? Data())
            .navigationTitle(manual.title ?? "Manual")
            .navigationBarTitleDisplayMode(.inline)
            .edgesIgnoringSafeArea(.bottom)
    }
}

struct PDFKitView: UIViewRepresentable {
    let data: Data
    
    func makeUIView(context: Context) -> PDFView {
        let pdfView = PDFView()
        
        // PDF-Dokument laden
        if let document = PDFDocument(data: data) {
            pdfView.document = document
        }
        
        // Grundkonfiguration
        pdfView.autoScales = true
        pdfView.displayMode = .singlePageContinuous
        pdfView.displayDirection = .vertical
        
        // Zoom-Einstellungen
        pdfView.minScaleFactor = 0.25
        pdfView.maxScaleFactor = 5.0
        pdfView.scaleFactor = 1.0
        
        // Benutzerinteraktionen aktivieren
        pdfView.isUserInteractionEnabled = true
        
        // Hintergrundfarbe
        pdfView.backgroundColor = UIColor.systemBackground
        
        return pdfView
    }
    
    func updateUIView(_ pdfView: PDFView, context: Context) {
        // Updates wenn nötig
    }
}

#Preview {
    // Preview mit Beispieldaten
    let context = PersistenceController.preview.container.viewContext
    let manual = Manual(context: context)
    manual.title = "Beispiel Manual"
    manual.fileName = "beispiel.pdf"
    manual.dateAdded = Date()
    manual.fileData = Data() // In der Praxis würden hier echte PDF-Daten stehen
    
    return PDFViewerView(manual: manual)
} 
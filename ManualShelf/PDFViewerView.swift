//
//  PDFViewerView.swift
//  ManualShelf
//
//  Created by Christian Bram on 02.06.25.
//

import SwiftUI
import PDFKit

struct PDFViewerView: View {
    @ObservedObject var manual: Manual // @ObservedObject, damit Änderungen am Manual die View aktualisieren
    @Environment(\.managedObjectContext) private var viewContext
    
    // Zustand für die aktuelle Drehung, initialisiert vom Manual-Objekt
    // Wird hier nicht direkt als @State verwendet, da die Quelle der Wahrheit das manual-Objekt ist.
    // Die Buttons ändern direkt manual.pdfRotationDegrees
    
    var body: some View {
        Group {
            if let fileData = manual.fileData, !fileData.isEmpty, PDFDocument(data: fileData) != nil {
                PDFKitView(data: fileData, rotationAngle: manual.pdfRotationDegrees) // Übergabe des Winkels
            } else {
                VStack(spacing: 15) {
                    Image(systemName: "doc.text.fill") // Symbol für ein Dokument
                        .font(.system(size: 70))
                        .foregroundColor(.secondary)
                    Text("PDF nicht verfügbar")
                        .font(.title2)
                        .foregroundColor(.secondary)
                    Text(manual.fileData == nil ? "Für dieses Manual wurden keine PDF-Daten gespeichert." : "Die PDF-Daten konnten nicht geladen oder dargestellt werden.")
                        .font(.callout)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
            }
        }
        .navigationTitle(manual.title ?? "Manual")
        .navigationBarTitleDisplayMode(.inline)
        .edgesIgnoringSafeArea(.bottom) // Gilt für PDFKitView, bei Fehleransicht ggf. anpassen oder entfernen
        .toolbar {
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
    
    private func rotatePDF(by degrees: Int16) {
        var newRotation = manual.pdfRotationDegrees + degrees
        // Normalisiere den Winkel auf 0, 90, 180, 270
        if newRotation >= 360 { newRotation -= 360 }
        if newRotation < 0 { newRotation += 360 }
        
        manual.pdfRotationDegrees = newRotation
        
        // Speichere die Änderung im Kontext
        do {
            try viewContext.save()
        } catch {
            // Fehlerbehandlung, z.B. Alert anzeigen
            print("Fehler beim Speichern der PDF-Drehung: \(error.localizedDescription)")
        }
    }
}

struct PDFKitView: UIViewRepresentable {
    let data: Data
    let rotationAngle: Int16 // Winkel als Int16
    
    func makeUIView(context: Context) -> PDFView {
        let pdfView = PDFView()
        
        // PDF-Dokument laden
        if let document = PDFDocument(data: data) {
            pdfView.document = document
            // Wende die initiale Drehung an, wenn das Dokument geladen wird
            applyRotation(to: document, angle: rotationAngle, forView: pdfView)
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
        // Wird aufgerufen, wenn sich `data` oder `rotationAngle` ändern
        if let document = pdfView.document {
            applyRotation(to: document, angle: rotationAngle, forView: pdfView)
        } else if let newDocumentData = PDFDocument(data: data) { // Falls Dokument neu geladen werden muss
            pdfView.document = newDocumentData
            applyRotation(to: newDocumentData, angle: rotationAngle, forView: pdfView)
        }
    }
    
    private func applyRotation(to document: PDFDocument, angle: Int16, forView pdfView: PDFView) {
        // Speichere die aktuelle Seite und Skalierung, um sie nach der Drehung wiederherzustellen
        let currentPageIndex = pdfView.currentPage?.pageRef?.pageNumber ?? 1
        let currentScaleFactor = pdfView.scaleFactor
        
        for i in 0..<document.pageCount {
            if let page = document.page(at: i) {
                page.rotation = Int(angle) // PDFPage.rotation erwartet Int
            }
        }
        // Die Rotation kann die Darstellung beeinflussen, daher muss ggf. die Ansicht aktualisiert werden.
        // Manchmal ist ein `layoutDocumentView()` oder ein Neusetzen der Seite nötig,
        // damit die PDFView die geänderte Seitendrehung korrekt darstellt und skaliert.
        pdfView.layoutDocumentView() // Wichtig, um die Ansicht zu aktualisieren
        pdfView.goToFirstPage(nil) // Gehe zur ersten Seite, um sicherzustellen, dass etwas angezeigt wird
        
        // Versuche, zur vorherigen Seite und Skalierung zurückzukehren
        if let targetPage = document.page(at: currentPageIndex - 1) { // page(at:) ist 0-indexed
            pdfView.go(to: targetPage)
            pdfView.scaleFactor = currentScaleFactor
        } else if document.pageCount > 0, let firstPage = document.page(at: 0) {
            pdfView.go(to: firstPage)
            pdfView.scaleFactor = currentScaleFactor
        }
        pdfView.autoScales = true // Sicherstellen, dass autoScales nach der Manipulation aktiv ist
    }
}

#Preview {
    // Preview mit Beispieldaten
    let context = PersistenceController.preview.container.viewContext
    let manual = Manual(context: context)
    manual.title = "Beispiel Manual mit Drehung"
    manual.fileName = "beispiel.pdf"
    manual.dateAdded = Date()
    // Erstelle Dummy-PDF-Daten für die Vorschau, wenn möglich
    // oder verwende ein echtes kleines PDF als Data
    // manual.fileData = Data() // Hier echte PDF-Daten für eine sinnvolle Vorschau einfügen
    manual.pdfRotationDegrees = 0 // Startwinkel für Preview
    
    return NavigationView { // NavigationView für den Preview, damit der Titel sichtbar ist
        PDFViewerView(manual: manual)
            .environment(\.managedObjectContext, context)
    }
} 
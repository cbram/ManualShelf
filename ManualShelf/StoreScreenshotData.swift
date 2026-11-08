//
//  StoreScreenshotData.swift
//  ManualShelf
//
//  Demo data for the App Store screenshots (SPEC-005), DEBUG builds only.
//  Everything is generated here: fictional products, lorem ipsum text, drawn covers.
//  No real manufacturers, brands or third-party content.
//

#if DEBUG
import CoreData
import UIKit

extension PersistenceController {
    /// In-memory store with localized demo manuals, never mirrored to iCloud.
    @MainActor
    static func storeScreenshotData(german: Bool) -> PersistenceController {
        let result = PersistenceController(inMemory: true)
        StoreScreenshotData(german: german, context: result.container.viewContext).insertAll()
        return result
    }
}

private struct DemoFile {
    let name: String
    let isPDF: Bool
}

private struct DemoManual {
    let title: String
    let model: String
    let files: [DemoFile]
    let tags: [String]
    let daysAgo: Int
}

@MainActor
private struct StoreScreenshotData {
    let german: Bool
    let context: NSManagedObjectContext

    private static let pageSize = CGSize(width: 595, height: 842) // A4 in points
    private static let photoSize = CGSize(width: 1200, height: 900)
    private static let secondsPerDay: TimeInterval = 86_400
    private static let jpegQuality: CGFloat = 0.85
    // Okabe-Ito colours, safe for colour-vision deficiencies
    private static let coverColors: [UIColor] = [
        UIColor(red: 0.00, green: 0.45, blue: 0.70, alpha: 1),
        UIColor(red: 0.90, green: 0.62, blue: 0.00, alpha: 1),
        UIColor(red: 0.00, green: 0.62, blue: 0.45, alpha: 1),
        UIColor(red: 0.80, green: 0.47, blue: 0.65, alpha: 1),
        UIColor(red: 0.34, green: 0.71, blue: 0.91, alpha: 1),
        UIColor(red: 0.84, green: 0.37, blue: 0.00, alpha: 1)
    ]
    private static let loremIpsum = "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor "
        + "incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation "
        + "ullamco laboris nisi ut aliquip ex ea commodo consequat."

    private func text(_ english: String, _ germanText: String) -> String { german ? germanText : english }

    private var manuals: [DemoManual] {
        let kitchen = text("Kitchen", "Küche")
        let warranty = text("Warranty", "Garantie")
        let electronics = text("Electronics", "Elektronik")
        let office = text("Office", "Büro")
        let camper = text("Camper", "Wohnmobil")
        let heating = text("Heating", "Heizung")
        let garden = text("Garden", "Garten")
        let workshop = text("Workshop", "Werkstatt")
        let household = text("Household", "Haushalt")
        return [
            DemoManual(title: text("Manual Universal Device XY-2000", "Anleitung Universalgerät XY-2000"),
                       model: "XY-2000",
                       files: [DemoFile(name: text("XY-2000 Manual.pdf", "XY-2000 Anleitung.pdf"), isPDF: true),
                               DemoFile(name: text("XY-2000 Quick Start.jpg", "XY-2000 Kurzanleitung.jpg"), isPDF: false),
                               DemoFile(name: text("XY-2000 Warranty Card.pdf", "XY-2000 Garantiekarte.pdf"), isPDF: true)],
                       tags: [household, kitchen, electronics, warranty, office, workshop], daysAgo: 1),
            DemoManual(title: text("Smartphone User Guide", "Smartphone-Bedienungsanleitung"),
                       model: "SP-12",
                       files: [DemoFile(name: text("SP-12 User Guide.pdf", "SP-12 Bedienungsanleitung.pdf"), isPDF: true)],
                       tags: [electronics, office], daysAgo: 3),
            DemoManual(title: text("Coffee Machine CM-300", "Kaffeemaschine CM-300"),
                       model: "CM-300",
                       files: [DemoFile(name: text("CM-300 Manual.pdf", "CM-300 Anleitung.pdf"), isPDF: true),
                               DemoFile(name: text("CM-300 Descaling.jpg", "CM-300 Entkalken.jpg"), isPDF: false)],
                       tags: [kitchen, warranty], daysAgo: 8),
            DemoManual(title: text("Camper Heater H-4", "Wohnmobil-Heizung H-4"),
                       model: "H-4",
                       files: [DemoFile(name: text("H-4 Installation.pdf", "H-4 Einbau.pdf"), isPDF: true)],
                       tags: [camper, heating], daysAgo: 15),
            DemoManual(title: text("Garden Pump GP-55", "Gartenpumpe GP-55"),
                       model: "GP-55",
                       files: [DemoFile(name: text("GP-55 Manual.pdf", "GP-55 Anleitung.pdf"), isPDF: true)],
                       tags: [garden], daysAgo: 30),
            DemoManual(title: text("Cordless Drill D-18", "Akkuschrauber D-18"),
                       model: "D-18",
                       files: [DemoFile(name: text("D-18 Manual.pdf", "D-18 Anleitung.pdf"), isPDF: true)],
                       tags: [workshop, warranty], daysAgo: 45)
        ]
    }

    func insertAll() {
        var tagsByName: [String: ManualTag] = [:]
        for (index, demo) in manuals.enumerated() {
            let color = Self.coverColors[index % Self.coverColors.count]
            let manual = Manual(context: context)
            manual.title = demo.title
            manual.dateAdded = Date().addingTimeInterval(-Double(demo.daysAgo) * Self.secondsPerDay)
            for demoFile in demo.files {
                let file = ManualFile(context: context)
                file.fileName = demoFile.name
                file.fileType = demoFile.isPDF ? "pdf" : "jpg"
                file.dateAdded = manual.dateAdded
                file.fileData = demoFile.isPDF
                    ? makePDF(title: demo.title, model: demo.model, color: color)
                    : makePhoto(model: demo.model, color: color)
                for tagName in demo.tags {
                    if tagsByName[tagName] == nil {
                        let newTag = ManualTag(context: context)
                        newTag.name = tagName
                        tagsByName[tagName] = newTag
                    }
                    if let tag = tagsByName[tagName] {
                        file.addToManualTags(tag)
                    }
                }
                manual.addToFiles(file)
            }
        }
        do {
            try context.save()
        } catch {
            fatalError("Store screenshot data could not be saved: \(error)")
        }
    }

    // MARK: - Generated content

    /// Cover page with a drawn device, then chapter pages with lorem ipsum.
    private func makePDF(title: String, model: String, color: UIColor) -> Data {
        let bounds = CGRect(origin: .zero, size: Self.pageSize)
        let chapters = german
            ? ["1 Sicherheitshinweise", "2 Inbetriebnahme", "3 Bedienung", "4 Reinigung und Pflege"]
            : ["1 Safety Instructions", "2 Getting Started", "3 Operation", "4 Cleaning and Care"]
        return UIGraphicsPDFRenderer(bounds: bounds).pdfData { context in
            context.beginPage()
            color.setFill()
            UIRectFill(CGRect(x: 0, y: 0, width: bounds.width, height: bounds.height * 0.55))
            drawDevice(in: CGRect(x: 170, y: 90, width: 255, height: 280))
            draw(model, at: CGPoint(x: 48, y: 500), size: 56, weight: .heavy)
            draw(title, at: CGPoint(x: 48, y: 580), size: 22, weight: .semibold, width: bounds.width - 96)
            draw(text("User Manual", "Bedienungsanleitung"), at: CGPoint(x: 48, y: 760), size: 18, weight: .regular)
            for chapter in chapters {
                context.beginPage()
                draw(chapter, at: CGPoint(x: 48, y: 60), size: 24, weight: .bold)
                var y: CGFloat = 120
                for _ in 0..<5 {
                    draw(Self.loremIpsum, at: CGPoint(x: 48, y: y), size: 12, weight: .regular, width: bounds.width - 96)
                    y += 110
                }
            }
        }
    }

    /// A drawn "photo" of a quick start sheet.
    private func makePhoto(model: String, color: UIColor) -> Data {
        let image = UIGraphicsImageRenderer(size: Self.photoSize).image { _ in
            UIColor.systemGray6.setFill()
            UIRectFill(CGRect(origin: .zero, size: Self.photoSize))
            color.setFill()
            UIRectFill(CGRect(x: 0, y: 0, width: Self.photoSize.width, height: 140))
            draw("\(model) – \(text("Quick Start", "Kurzanleitung"))", at: CGPoint(x: 60, y: 40), size: 56, weight: .bold)
            for step in 0..<3 {
                let x = 60 + CGFloat(step) * 370
                let frame = CGRect(x: x, y: 220, width: 320, height: 420)
                UIColor.white.setFill()
                UIBezierPath(roundedRect: frame, cornerRadius: 24).fill()
                drawDevice(in: frame.insetBy(dx: 70, dy: 90), color: color)
                draw("\(step + 1)", at: CGPoint(x: x + 24, y: 236), size: 48, weight: .heavy)
            }
            draw(Self.loremIpsum, at: CGPoint(x: 60, y: 690), size: 30, weight: .regular, width: Self.photoSize.width - 120)
        }
        return image.jpegData(compressionQuality: Self.jpegQuality) ?? Data()
    }

    /// Simple generic device: body, display and three buttons.
    private func drawDevice(in frame: CGRect, color: UIColor = .white) {
        let lineWidth = frame.width * 0.03
        color.setStroke()
        let body = UIBezierPath(roundedRect: frame, cornerRadius: frame.width * 0.12)
        body.lineWidth = lineWidth
        body.stroke()
        let screen = UIBezierPath(roundedRect: CGRect(x: frame.minX + frame.width * 0.15, y: frame.minY + frame.height * 0.12,
                                                      width: frame.width * 0.7, height: frame.height * 0.4),
                                  cornerRadius: frame.width * 0.04)
        screen.lineWidth = lineWidth
        screen.stroke()
        for index in 0..<3 {
            let diameter = frame.width * 0.16
            let x = frame.minX + frame.width * (0.2 + CGFloat(index) * 0.22)
            let knob = UIBezierPath(ovalIn: CGRect(x: x, y: frame.minY + frame.height * 0.68, width: diameter, height: diameter))
            knob.lineWidth = lineWidth
            knob.stroke()
        }
    }

    private func draw(_ string: String, at point: CGPoint, size: CGFloat, weight: UIFont.Weight, width: CGFloat? = nil) {
        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: size, weight: weight),
            .foregroundColor: UIColor.black
        ]
        if let width {
            (string as NSString).draw(in: CGRect(x: point.x, y: point.y, width: width, height: .greatestFiniteMagnitude),
                                      withAttributes: attributes)
        } else {
            (string as NSString).draw(at: point, withAttributes: attributes)
        }
    }
}
#endif

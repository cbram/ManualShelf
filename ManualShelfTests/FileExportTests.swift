//
//  FileExportTests.swift
//  ManualShelfTests
//

import Foundation
import Testing
@testable import ManualShelf

struct FileExportTests {

    @Test func keepsNameWithExtension() {
        #expect(FileExport.exportFileName(storedName: "Manual.pdf", fileType: "pdf") == "Manual.pdf")
    }

    @Test func addsMissingExtensionFromType() {
        #expect(FileExport.exportFileName(storedName: "Scan", fileType: "jpeg") == "Scan.jpeg")
    }

    @Test func replacesPathSeparators() {
        #expect(FileExport.exportFileName(storedName: "A/B:C.png", fileType: "png") == "A-B-C.png")
    }

    @Test func emptyNameFallsBackToLocalizedFile() {
        let name = FileExport.exportFileName(storedName: "  ", fileType: "pdf")
        #expect(name == "\(String(localized: "File")).pdf")
    }

    @Test func writesDataUnderExportName() throws {
        let data = Data("%PDF-1.4 test".utf8)
        let url = try FileExport.writeTemporaryFile(data: data, fileName: "Test.pdf", folderKey: "tests-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: url.deletingLastPathComponent()) }
        #expect(url.lastPathComponent == "Test.pdf")
        #expect(try Data(contentsOf: url) == data)
    }
}

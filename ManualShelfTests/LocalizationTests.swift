//
//  LocalizationTests.swift
//  ManualShelfTests
//

import Foundation
import Testing
@testable import ManualShelf

struct LocalizationTests {

    private static func bundle(forLanguage language: String) throws -> Bundle {
        let path = try #require(Bundle.main.path(forResource: language, ofType: "lproj"))
        return try #require(Bundle(path: path))
    }

    @Test(arguments: [
        ("en", 1, "1 file"),
        ("en", 3, "3 files"),
        ("de", 1, "1 Datei"),
        ("de", 3, "3 Dateien")
    ])
    func fileCountUsesPluralForms(language: String, count: Int, expected: String) throws {
        let text = String(
            localized: "\(count) files",
            bundle: try Self.bundle(forLanguage: language),
            locale: Locale(identifier: language)
        )
        #expect(text == expected)
    }

    @Test func germanTextKeepsPlaceholderArgument() throws {
        let fileType = "heic"
        let text = String(
            localized: "File type \(fileType) is not supported.",
            bundle: try Self.bundle(forLanguage: "de"),
            locale: Locale(identifier: "de")
        )
        #expect(text == "Dateityp heic wird nicht unterstützt.")
    }

    @Test func germanUsesInformalAddress() throws {
        let text = String(
            localized: "Please enter a title and select at least one file.",
            bundle: try Self.bundle(forLanguage: "de"),
            locale: Locale(identifier: "de")
        )
        #expect(text == "Bitte gib einen Titel an und wähle mindestens eine Datei aus.")
    }
}

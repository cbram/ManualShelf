//
//  TagColorTests.swift
//  ManualShelfTests
//

import Testing
@testable import ManualShelf

struct TagColorTests {

    // Fixed expectations from FNV-1a; a per-process seeded hash (hashValue) breaks these.
    @Test(arguments: [
        ("Wohnmobil", 0),
        ("Garten", 1),
        ("Werkzeug", 3),
        ("Küche", 4)
    ])
    func paletteIndexIsStable(name: String, expectedIndex: Int) {
        #expect(TagColor.paletteIndex(forName: name) == expectedIndex)
    }

    @Test func sameNameGivesSameColorIgnoringCaseAndWhitespace() {
        #expect(TagColor.forName("Küche") == TagColor.forName("Küche"))
        #expect(TagColor.forName("Küche") == TagColor.forName("  küche "))
        #expect(TagColor.forName("Küche") == TagColor.forName("KÜCHE"))
    }

    @Test func missingNameMapsToAPaletteColor() {
        #expect(TagColor.palette.contains(TagColor.forName(nil)))
    }
}

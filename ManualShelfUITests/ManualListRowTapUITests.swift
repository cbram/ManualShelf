//
//  ManualListRowTapUITests.swift
//  ManualShelfUITests
//
//  SPEC-004: a tap anywhere in a row of the manual list opens the manual,
//  not only a tap on the disclosure arrow.
//

import XCTest

@MainActor
final class ManualListRowTapUITests: XCTestCase {

    // Must match ManualShelfApp.uiTestSampleDataArgument and PersistenceController.preview
    private static let sampleDataArgument = "-uiTestSampleData"
    private static let sampleTitle = "Beispiel-Manual 0"
    private static let gapBesideTitle: CGFloat = 24
    private static let thumbnailCenterInset: CGFloat = 42
    private static let chipInset: CGFloat = 16
    private static let arrowClearance: CGFloat = 60
    private static let dateLineMarker = " - "
    private static let timeout: TimeInterval = 5

    private var app: XCUIApplication!

    override func setUp() async throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments.append(Self.sampleDataArgument)
        app.launch()
    }

    func testTapOnTitleOpensManual() throws {
        try sampleTitleText().tap()
        assertManualOpened()
    }

    func testTapOnEmptySpaceBesideTitleOpensManual() throws {
        let title = try sampleTitleText()
        let row = try sampleRow()
        // Beside the title, but always left of the arrow
        let x = min(title.frame.maxX + Self.gapBesideTitle, row.frame.maxX - Self.arrowClearance)
        XCTAssertGreaterThan(x, title.frame.maxX, "no empty space beside the title")
        let point = CGPoint(x: x, y: title.frame.midY)
        tap(at: point)
        assertManualOpened()
    }

    func testTapOnThumbnailOpensManual() throws {
        let row = try sampleRow()
        tap(at: CGPoint(x: row.frame.minX + Self.thumbnailCenterInset, y: row.frame.midY))
        assertManualOpened()
    }

    // The tag chips sit between the title and the date line; up to 1.3.0 a scroll view there swallowed taps
    func testTapOnTagChipOpensManual() throws {
        let title = try sampleTitleText()
        tap(at: CGPoint(x: title.frame.minX + Self.chipInset, y: try tagBandMidY()))
        assertManualOpened()
    }

    func testTapOnEmptySpaceInTagBandOpensManual() throws {
        let row = try sampleRow()
        tap(at: CGPoint(x: row.frame.maxX - Self.arrowClearance, y: try tagBandMidY()))
        assertManualOpened()
    }

    // MARK: - Helpers

    private func sampleRow() throws -> XCUIElement {
        let row = app.cells.containing(.staticText, identifier: Self.sampleTitle).firstMatch
        XCTAssertTrue(row.waitForExistence(timeout: Self.timeout), "sample row not found")
        return row
    }

    private func sampleTitleText() throws -> XCUIElement {
        try existing(sampleRow().staticTexts[Self.sampleTitle].firstMatch, "title")
    }

    // Vertical centre between the title and the date line ("1 file - Added: …")
    private func tagBandMidY() throws -> CGFloat {
        let title = try sampleTitleText()
        let dateLine = try existing(
            sampleRow().staticTexts.matching(NSPredicate(format: "label CONTAINS %@", Self.dateLineMarker)).firstMatch,
            "date line"
        )
        return (title.frame.maxY + dateLine.frame.minY) / 2
    }

    private func existing(_ element: XCUIElement, _ name: String) throws -> XCUIElement {
        XCTAssertTrue(element.waitForExistence(timeout: Self.timeout), "\(name) not found")
        return element
    }

    // Taps a screen point; coordinates are taken from the app window so no element hit-test decides
    private func tap(at point: CGPoint) {
        let origin = app.coordinate(withNormalizedOffset: .zero)
        origin.withOffset(CGVector(dx: point.x, dy: point.y)).tap()
    }

    private func assertManualOpened() {
        XCTAssertTrue(
            app.navigationBars[Self.sampleTitle].waitForExistence(timeout: Self.timeout),
            "manual view did not open"
        )
    }
}

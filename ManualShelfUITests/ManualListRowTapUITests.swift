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
    // This sample manual has more tags than fit into one line
    private static let wrappingTagsTitle = "Beispiel-Manual 1"
    private static let secondTagLineOffset: CGFloat = 16
    private static let minimumWrapFactor: CGFloat = 1.5
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

    // Tags that do not fit wrap into further lines instead of a scroll view (SPEC-004, decision 08.11.)
    func testTapOnSecondTagLineOpensManual() throws {
        let oneLineBand = try tagBand(of: Self.sampleTitle)
        let wrappedBand = try tagBand(of: Self.wrappingTagsTitle)
        XCTAssertGreaterThan(wrappedBand.height, oneLineBand.height * Self.minimumWrapFactor, "tags did not wrap")
        let title = try titleText(of: Self.wrappingTagsTitle)
        tap(at: CGPoint(x: title.frame.minX + Self.chipInset, y: wrappedBand.maxY - Self.secondTagLineOffset))
        assertManualOpened(Self.wrappingTagsTitle)
    }

    // MARK: - Helpers

    private func sampleRow() throws -> XCUIElement {
        try row(of: Self.sampleTitle)
    }

    private func sampleTitleText() throws -> XCUIElement {
        try titleText(of: Self.sampleTitle)
    }

    private func tagBandMidY() throws -> CGFloat {
        try tagBand(of: Self.sampleTitle).midY
    }

    private func row(of title: String) throws -> XCUIElement {
        let row = app.cells.containing(.staticText, identifier: title).firstMatch
        XCTAssertTrue(row.waitForExistence(timeout: Self.timeout), "row \(title) not found")
        return row
    }

    private func titleText(of title: String) throws -> XCUIElement {
        try existing(row(of: title).staticTexts[title].firstMatch, "title")
    }

    // Area between the title and the date line ("1 file - Added: …") where the tag chips sit
    private func tagBand(of title: String) throws -> CGRect {
        let row = try row(of: title)
        let titleFrame = try titleText(of: title).frame
        let dateLine = try existing(
            row.staticTexts.matching(NSPredicate(format: "label CONTAINS %@", Self.dateLineMarker)).firstMatch,
            "date line"
        )
        return CGRect(x: row.frame.minX, y: titleFrame.maxY,
                      width: row.frame.width, height: dateLine.frame.minY - titleFrame.maxY)
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

    private func assertManualOpened(_ title: String = sampleTitle) {
        XCTAssertTrue(
            app.navigationBars[title].waitForExistence(timeout: Self.timeout),
            "manual view did not open"
        )
    }
}

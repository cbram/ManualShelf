//
//  StoreScreenshotUITests.swift
//  ManualShelfUITests
//
//  SPEC-005: captures the App Store screenshots with the demo data (-storeScreenshotData).
//  Skipped in normal test runs; Scripts/store-screenshots.sh sets SHOT_DIR and SHOT_LANG
//  (passed to the runner as TEST_RUNNER_SHOT_DIR / TEST_RUNNER_SHOT_LANG).
//

import XCTest

@MainActor
final class StoreScreenshotUITests: XCTestCase {

    // Must match ManualShelfApp.storeScreenshotDataArgument
    private static let demoDataArgument = "-storeScreenshotData"
    private static let settleSeconds: UInt32 = 2
    private static let timeout: TimeInterval = 10

    private var app: XCUIApplication!
    private var outputDirectory: URL!
    private var isGerman = false

    override func setUp() async throws {
        let environment = ProcessInfo.processInfo.environment
        guard let directory = environment["SHOT_DIR"] else {
            throw XCTSkip("Only run by Scripts/store-screenshots.sh")
        }
        continueAfterFailure = false
        outputDirectory = URL(fileURLWithPath: directory)
        let language = environment["SHOT_LANG"] ?? "en"
        isGerman = language == "de"
        XCUIDevice.shared.orientation = .portrait
        app = XCUIApplication()
        app.launchArguments += [Self.demoDataArgument, "-AppleLanguages", "(\(language))",
                                "-AppleLocale", isGerman ? "de_DE" : "en_US"]
        app.launch()
    }

    func testCaptureStoreScreenshots() throws {
        let isPad = UIDevice.current.userInterfaceIdiom == .pad
        let mainTitle = localized("Manual Universal Device XY-2000", "Anleitung Universalgerät XY-2000")

        if isPad {
            // The iPad shows the list beside a detail, never an empty placeholder
            try tapText(localized("Smartphone User Guide", "Smartphone-Bedienungsanleitung"))
        } else {
            _ = try existing(app.staticTexts[mainTitle])
        }
        try capture("01-list")

        try tapText(mainTitle)
        try capture("02-detail")

        // Relaunch instead of navigating back: the back button sits in different places per device
        relaunch()
        try existing(app.buttons[localized("Electronics", "Elektronik")].firstMatch).tap()
        if isPad {
            try tapText(mainTitle)
        }
        try capture("03-tag-filter")

        relaunch()
        try existing(app.buttons[localized("Add Manual", "Manual hinzufügen")].firstMatch).tap()
        try tapText(localized("Load from URL...", "Aus URL laden..."))
        let addressField = try existing(app.textFields[localized("https://example.com/manual.pdf", "https://example.com/anleitung.pdf")])
        addressField.tap()
        addressField.typeText(localized("https://example.com/manuals/xy-2000.pdf", "https://example.com/anleitungen/xy-2000.pdf"))
        try capture("04-load-from-url")
    }

    private func relaunch() {
        app.terminate()
        app.launch()
    }

    private func localized(_ english: String, _ german: String) -> String {
        isGerman ? german : english
    }

    private func tapText(_ label: String) throws {
        try existing(app.staticTexts[label].firstMatch).tap()
    }

    @discardableResult
    private func existing(_ element: XCUIElement) throws -> XCUIElement {
        XCTAssertTrue(element.waitForExistence(timeout: Self.timeout), "missing: \(element)")
        return element
    }

    private func capture(_ name: String) throws {
        sleep(Self.settleSeconds)
        let png = XCUIScreen.main.screenshot().pngRepresentation
        try png.write(to: outputDirectory.appendingPathComponent("\(name).png"))
    }
}

//
//  URLDownloadTests.swift
//  ManualShelfTests
//

import Foundation
import Testing
import UniformTypeIdentifiers
@testable import ManualShelf

struct URLDownloadTests {

    // MARK: - Address

    @Test func acceptsHTTPSAddress() throws {
        let url = try URLDownload.validatedURL(from: " https://example.com/a.pdf ")
        #expect(url.absoluteString == "https://example.com/a.pdf")
    }

    @Test func addsHTTPSWhenSchemeIsMissing() throws {
        #expect(try URLDownload.validatedURL(from: "example.com/a.pdf").scheme == "https")
    }

    @Test func rejectsHTTP() {
        #expect(throws: URLDownload.DownloadError.notHTTPS) { try URLDownload.validatedURL(from: "http://example.com/a.pdf") }
    }

    @Test(arguments: ["", "ftp://example.com/a.pdf", "https://", "not a url"])
    func rejectsInvalidAddresses(text: String) {
        #expect(throws: URLDownload.DownloadError.invalidURL) { try URLDownload.validatedURL(from: text) }
    }

    // MARK: - File type

    @Test func detectsTypesFromContent() {
        #expect(URLDownload.detectFileType(of: Data("%PDF-1.7\n".utf8)) == .pdf)
        #expect(URLDownload.detectFileType(of: Data([0xFF, 0xD8, 0xFF, 0xE0, 0x00])) == .jpeg)
        #expect(URLDownload.detectFileType(of: Data([0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00])) == .png)
    }

    @Test func detectsPDFAfterLeadingBytes() {
        #expect(URLDownload.detectFileType(of: Data([0x0A, 0x0D]) + Data("%PDF-1.4".utf8)) == .pdf)
    }

    @Test func rejectsOtherContent() {
        #expect(URLDownload.detectFileType(of: Data("<html><body>Not found</body></html>".utf8)) == nil)
        #expect(URLDownload.detectFileType(of: Data()) == nil)
    }

    // MARK: - File name

    @Test func keepsMatchingExtension() {
        #expect(URLDownload.fileName(suggested: "Manual.pdf", type: .pdf) == "Manual.pdf")
        #expect(URLDownload.fileName(suggested: "photo.JPG", type: .jpeg) == "photo.JPG")
    }

    @Test func addsExtensionOfDetectedType() {
        #expect(URLDownload.fileName(suggested: "download", type: .png) == "download.png")
        #expect(URLDownload.fileName(suggested: "page.html", type: .pdf) == "page.html.pdf")
        #expect(URLDownload.fileName(suggested: nil, type: .pdf) == "Download.pdf")
    }

    // MARK: - Response checks

    @Test func acceptsSuccessStatus() throws {
        try URLDownload.validate(statusCode: 200)
    }

    @Test func rejectsErrorAndRedirectStatus() {
        #expect(throws: URLDownload.DownloadError.httpStatus(404)) { try URLDownload.validate(statusCode: 404) }
        #expect(throws: URLDownload.DownloadError.insecureRedirect) { try URLDownload.validate(statusCode: 302) }
    }

    @Test func enforcesSizeLimit() throws {
        try URLDownload.checkSize(Int64(URLDownload.maximumSize))
        try URLDownload.checkSize(-1)
        #expect(throws: URLDownload.DownloadError.tooLarge) { try URLDownload.checkSize(Int64(URLDownload.maximumSize) + 1) }
    }

    @Test func mapsNetworkErrors() {
        #expect(URLDownload.mappedError(URLError(.notConnectedToInternet)) as? URLDownload.DownloadError == .offline)
        #expect(URLDownload.mappedError(URLError(.timedOut)) as? URLDownload.DownloadError == .timedOut)
        #expect(URLDownload.mappedError(URLError(.appTransportSecurityRequiresSecureConnection)) as? URLDownload.DownloadError == .notHTTPS)
        #expect(URLDownload.mappedError(URLError(.cancelled)) is CancellationError)
    }

    @Test func germanErrorMessageKeepsNumber() throws {
        let path = try #require(Bundle.main.path(forResource: "de", ofType: "lproj"))
        let bundle = try #require(Bundle(path: path))
        let code = 404
        let text = String(localized: "The server reported an error (HTTP \(code)).", bundle: bundle, locale: Locale(identifier: "de"))
        #expect(text == "Der Server hat einen Fehler gemeldet (HTTP 404).")
    }
}

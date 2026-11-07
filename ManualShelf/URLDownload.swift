//
//  URLDownload.swift
//  ManualShelf
//

import Foundation
import UniformTypeIdentifiers

/// Downloads a manual file from an https address (issue 8).
enum URLDownload {
    static let maximumSizeInMegabytes = 50
    static let maximumSize = maximumSizeInMegabytes * 1024 * 1024
    static let timeout: TimeInterval = 60

    private static let pdfSignature: [UInt8] = Array("%PDF-".utf8)
    private static let pdfSignatureSearchLength = 1024
    private static let jpegSignature: [UInt8] = [0xFF, 0xD8, 0xFF]
    private static let pngSignature: [UInt8] = [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]
    fileprivate static let secureScheme = "https"
    private static let insecureScheme = "http"
    private static let successStatusCodes = 200..<300
    private static let redirectStatusCodes = 300..<400

    enum DownloadError: LocalizedError, Equatable {
        case invalidURL
        case notHTTPS
        case insecureRedirect
        case offline
        case timedOut
        case httpStatus(Int)
        case tooLarge
        case unsupportedType
        case emptyResponse
        case network(String)

        var errorDescription: String? {
            switch self {
            case .invalidURL: return String(localized: "This is not a valid web address.")
            case .notHTTPS: return String(localized: "Only secure https addresses are supported.")
            case .insecureRedirect: return String(localized: "The server redirected to an insecure address.")
            case .offline: return String(localized: "No internet connection.")
            case .timedOut: return String(localized: "The server did not respond in time.")
            case .httpStatus(let code): return String(localized: "The server reported an error (HTTP \(code)).")
            case .tooLarge: return String(localized: "The file is larger than \(URLDownload.maximumSizeInMegabytes) MB.")
            case .unsupportedType: return String(localized: "Only PDF, JPEG and PNG files are supported.")
            case .emptyResponse: return String(localized: "The server sent an empty file.")
            case .network(let message): return String(localized: "Download failed: \(message)")
            }
        }
    }

    /// Parses the typed address; adds `https://` when no scheme was typed.
    static func validatedURL(from text: String) throws -> URL {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        let withScheme = trimmed.contains("://") ? trimmed : "\(secureScheme)://\(trimmed)"
        guard let url = URL(string: withScheme), let host = url.host(), !host.isEmpty,
              let scheme = url.scheme?.lowercased() else {
            throw DownloadError.invalidURL
        }
        if scheme == insecureScheme { throw DownloadError.notHTTPS }
        guard scheme == secureScheme else { throw DownloadError.invalidURL }
        return url
    }

    /// File type from the content's signature, independent of what the server claims.
    static func detectFileType(of data: Data) -> UTType? {
        if data.starts(with: jpegSignature) { return .jpeg }
        if data.starts(with: pngSignature) { return .png }
        if data.prefix(pdfSignatureSearchLength).firstRange(of: pdfSignature) != nil { return .pdf }
        return nil
    }

    /// File name from the server's suggestion with an extension that matches the detected type.
    static func fileName(suggested: String?, type: UTType) -> String {
        let fallbackBaseName = "Download"
        var name = FileNaming.sanitized((suggested ?? "").trimmingCharacters(in: .whitespacesAndNewlines))
        if name.isEmpty { name = fallbackBaseName }
        let currentExtension = (name as NSString).pathExtension.lowercased()
        let matches = UTType(filenameExtension: currentExtension)?.conforms(to: type) ?? false
        if !matches, let preferredExtension = type.preferredFilenameExtension {
            name += ".\(preferredExtension)"
        }
        return name
    }

    static func validate(statusCode: Int) throws {
        if redirectStatusCodes.contains(statusCode) { throw DownloadError.insecureRedirect }
        guard successStatusCodes.contains(statusCode) else { throw DownloadError.httpStatus(statusCode) }
    }

    static func checkSize(_ byteCount: Int64) throws {
        if byteCount > Int64(maximumSize) { throw DownloadError.tooLarge }
    }

    /// Maps URL loading errors to the app's messages; cancellation stays cancellation.
    static func mappedError(_ error: Error) -> Error {
        guard let urlError = error as? URLError else { return error }
        switch urlError.code {
        case .cancelled: return CancellationError()
        case .notConnectedToInternet, .networkConnectionLost, .dataNotAllowed: return DownloadError.offline
        case .timedOut: return DownloadError.timedOut
        case .appTransportSecurityRequiresSecureConnection: return DownloadError.notHTTPS
        case .badURL, .unsupportedURL: return DownloadError.invalidURL
        default: return DownloadError.network(urlError.localizedDescription)
        }
    }

    /// Downloads and checks the file; returns its data, a file name and the detected type.
    static func download(from url: URL) async throws -> (Data, String, UTType) {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.timeoutIntervalForRequest = timeout
        let session = URLSession(configuration: configuration)
        defer { session.finishTasksAndInvalidate() }
        do {
            let (bytes, response) = try await session.bytes(from: url, delegate: SecureRedirectGuard())
            guard let httpResponse = response as? HTTPURLResponse else { throw DownloadError.emptyResponse }
            try validate(statusCode: httpResponse.statusCode)
            try checkSize(httpResponse.expectedContentLength)
            var data = Data()
            for try await byte in bytes {
                data.append(byte)
                try checkSize(Int64(data.count))
            }
            guard !data.isEmpty else { throw DownloadError.emptyResponse }
            guard let type = detectFileType(of: data) else { throw DownloadError.unsupportedType }
            return (data, fileName(suggested: httpResponse.suggestedFilename, type: type), type)
        } catch {
            throw mappedError(error)
        }
    }
}

/// Follows redirects only to https addresses; any other redirect ends in a 3xx response.
private final class SecureRedirectGuard: NSObject, URLSessionTaskDelegate, Sendable {
    func urlSession(_ session: URLSession, task: URLSessionTask,
                    willPerformHTTPRedirection response: HTTPURLResponse,
                    newRequest request: URLRequest) async -> URLRequest? {
        request.url?.scheme?.lowercased() == URLDownload.secureScheme ? request : nil
    }
}

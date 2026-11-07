//
//  FileThumbnailTests.swift
//  ManualShelfTests
//

import Testing
import UIKit
@testable import ManualShelf

struct FileThumbnailTests {
    private static let pixelSide: CGFloat = 100

    private static func pngData(width: CGFloat, height: CGFloat) -> Data {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        return UIGraphicsImageRenderer(size: CGSize(width: width, height: height), format: format).pngData { context in
            UIColor.systemBlue.setFill()
            context.fill(CGRect(x: 0, y: 0, width: width, height: height))
        }
    }

    private static func pdfData() -> Data {
        UIGraphicsPDFRenderer(bounds: CGRect(x: 0, y: 0, width: 600, height: 800)).pdfData { context in
            context.beginPage()
            UIColor.systemOrange.setFill()
            context.fill(CGRect(x: 50, y: 50, width: 200, height: 200))
        }
    }

    @Test func imageThumbnailFitsTheRequestedSize() throws {
        let thumbnail = try #require(FileThumbnailCache.makeThumbnail(
            data: Self.pngData(width: 400, height: 200), isPDF: false, rotation: 0, pixelSide: Self.pixelSide))
        #expect(thumbnail.size.width * thumbnail.scale <= Self.pixelSide + 1)
        #expect(thumbnail.size.width > thumbnail.size.height)
    }

    @Test func quarterTurnSwapsImageSides() throws {
        let thumbnail = try #require(FileThumbnailCache.makeThumbnail(
            data: Self.pngData(width: 400, height: 200), isPDF: false, rotation: 90, pixelSide: Self.pixelSide))
        #expect(thumbnail.size.height > thumbnail.size.width)
    }

    @Test func pdfThumbnailUsesFirstPageAndRotation() throws {
        let upright = try #require(FileThumbnailCache.makeThumbnail(
            data: Self.pdfData(), isPDF: true, rotation: 0, pixelSide: Self.pixelSide))
        let turned = try #require(FileThumbnailCache.makeThumbnail(
            data: Self.pdfData(), isPDF: true, rotation: 90, pixelSide: Self.pixelSide))
        #expect(upright.size.height > upright.size.width)
        #expect(turned.size.width > turned.size.height)
    }

    @Test func invalidDataGivesNoThumbnail() {
        #expect(FileThumbnailCache.makeThumbnail(data: Data([1, 2, 3]), isPDF: false, rotation: 0, pixelSide: Self.pixelSide) == nil)
        #expect(FileThumbnailCache.makeThumbnail(data: Data([1, 2, 3]), isPDF: true, rotation: 0, pixelSide: Self.pixelSide) == nil)
    }
}

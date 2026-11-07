//
//  FileThumbnail.swift
//  ManualShelf
//

import SwiftUI
import PDFKit
import UniformTypeIdentifiers

/// Preview image of a stored file (issue 3): the first PDF page or the scaled-down image,
/// rotated like in the viewer. Falls back to the file type symbol while loading or on failure.
struct FileThumbnailView: View {
    @ObservedObject var file: ManualFile
    let size: CGFloat

    @State private var thumbnail: UIImage?

    var body: some View {
        Group {
            if let thumbnail {
                Image(uiImage: thumbnail)
                    .resizable()
                    .scaledToFit()
            } else {
                Image(systemName: isPDF ? "doc.text.fill" : "photo.fill")
                    .font(.title2)
                    .foregroundColor(.accentColor)
            }
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
        .task(id: cacheKey) {
            guard let data = file.fileData, !data.isEmpty else { return }
            thumbnail = await FileThumbnailCache.shared.thumbnail(
                key: cacheKey, data: data, isPDF: isPDF, rotation: rotationDegrees, side: size
            )
        }
    }

    private var isPDF: Bool {
        file.fileType?.lowercased() == UTType.pdf.preferredFilenameExtension
    }

    private var rotationDegrees: Int {
        Int(isPDF ? file.pdfRotationDegrees : file.imageRotationDegrees)
    }

    // Changes whenever the file, its data size or its rotation changes
    private var cacheKey: String {
        "\(file.objectID.uriRepresentation().absoluteString)|\(file.fileData?.count ?? 0)|\(rotationDegrees)|\(size)"
    }
}

/// In-memory cache for thumbnails; nothing is stored in the data model.
@MainActor
final class FileThumbnailCache {
    static let shared = FileThumbnailCache()

    private let cache = NSCache<NSString, UIImage>()

    func thumbnail(key: String, data: Data, isPDF: Bool, rotation: Int, side: CGFloat) async -> UIImage? {
        if let cached = cache.object(forKey: key as NSString) {
            return cached
        }
        let pixelSide = side * UITraitCollection.current.displayScale
        let image = await Task.detached(priority: .utility) {
            FileThumbnailCache.makeThumbnail(data: data, isPDF: isPDF, rotation: rotation, pixelSide: pixelSide)
        }.value
        if let image {
            cache.setObject(image, forKey: key as NSString)
        }
        return image
    }

    nonisolated static func makeThumbnail(data: Data, isPDF: Bool, rotation: Int, pixelSide: CGFloat) -> UIImage? {
        let targetSize = CGSize(width: pixelSide, height: pixelSide)
        if isPDF {
            guard let page = PDFDocument(data: data)?.page(at: 0) else { return nil }
            page.rotation = rotation
            return page.thumbnail(of: targetSize, for: .cropBox)
        }
        guard let image = UIImage(data: data),
              let thumbnail = image.preparingThumbnail(of: fittingSize(of: image.size, in: targetSize)) else {
            return nil
        }
        return rotated(thumbnail, byDegrees: rotation)
    }

    private nonisolated static func fittingSize(of size: CGSize, in bounds: CGSize) -> CGSize {
        guard size.width > 0, size.height > 0 else { return bounds }
        let scale = min(bounds.width / size.width, bounds.height / size.height, 1)
        return CGSize(width: size.width * scale, height: size.height * scale)
    }

    private nonisolated static func rotated(_ image: UIImage, byDegrees degrees: Int) -> UIImage {
        let quarterTurns = ((degrees / 90) % 4 + 4) % 4
        guard quarterTurns != 0 else { return image }
        let swapsSides = quarterTurns % 2 == 1
        let newSize = swapsSides ? CGSize(width: image.size.height, height: image.size.width) : image.size
        let format = UIGraphicsImageRendererFormat()
        format.scale = image.scale
        return UIGraphicsImageRenderer(size: newSize, format: format).image { context in
            context.cgContext.translateBy(x: newSize.width / 2, y: newSize.height / 2)
            context.cgContext.rotate(by: CGFloat(quarterTurns) * .pi / 2)
            image.draw(in: CGRect(x: -image.size.width / 2, y: -image.size.height / 2,
                                  width: image.size.width, height: image.size.height))
        }
    }
}

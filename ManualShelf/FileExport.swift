//
//  FileExport.swift
//  ManualShelf
//

import Foundation

/// Writes stored manual files to temporary files so they can be shared (issue 13).
enum FileExport {
    private static let exportFolderName = "Export"

    /// Name used when sharing: the stored file name, made safe for the file system, with the
    /// stored type's extension added when the name has none.
    static func exportFileName(storedName: String?, fileType: String?) -> String {
        var name = (storedName ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        name = name.replacingOccurrences(of: "/", with: "-").replacingOccurrences(of: ":", with: "-")
        if name.isEmpty {
            name = String(localized: "File")
        }
        if let fileType, !fileType.isEmpty, (name as NSString).pathExtension.isEmpty {
            name += ".\(fileType)"
        }
        return name
    }

    /// Temporary copy of a stored file under its export name; nil if the file has no data.
    static func temporaryURL(for file: ManualFile) throws -> URL? {
        guard let data = file.fileData, !data.isEmpty else { return nil }
        // One folder per file keeps equal file names of different files apart
        let folderKey = file.objectID.uriRepresentation().pathComponents.suffix(2).joined(separator: "-")
        return try writeTemporaryFile(
            data: data,
            fileName: exportFileName(storedName: file.fileName, fileType: file.fileType),
            folderKey: folderKey
        )
    }

    /// Writes data to `<tmp>/Export/<folderKey>/<fileName>`, replacing an earlier copy.
    static func writeTemporaryFile(data: Data, fileName: String, folderKey: String) throws -> URL {
        let folder = FileManager.default.temporaryDirectory
            .appendingPathComponent(exportFolderName, isDirectory: true)
            .appendingPathComponent(folderKey, isDirectory: true)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        let url = folder.appendingPathComponent(fileName)
        try data.write(to: url, options: .atomic)
        return url
    }
}

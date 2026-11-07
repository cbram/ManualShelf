//
//  FileNaming.swift
//  ManualShelf
//

import Foundation

/// Rules for user-chosen file names: the user edits only the name, the extension is kept.
enum FileNaming {
    private static let forbiddenCharacters = ["/", ":"]
    private static let replacementCharacter = "-"

    /// Replaces characters that are not allowed in file names.
    static func sanitized(_ name: String) -> String {
        forbiddenCharacters.reduce(name) { $0.replacingOccurrences(of: $1, with: replacementCharacter) }
    }

    /// The name without its extension, as shown for editing.
    static func baseName(of fileName: String) -> String {
        (fileName as NSString).deletingPathExtension
    }

    /// The extension of a file name, or the fallback when the name has none.
    static func fileExtension(of fileName: String, fallback: String?) -> String {
        let pathExtension = (fileName as NSString).pathExtension
        return pathExtension.isEmpty ? (fallback ?? "") : pathExtension
    }

    /// New file name from the typed name: trimmed and sanitized, with the current extension kept.
    /// An empty name keeps the current file name; a typed copy of the extension is not doubled.
    static func renamed(currentFileName: String, newBaseName: String, fallbackExtension: String?) -> String {
        let pathExtension = fileExtension(of: currentFileName, fallback: fallbackExtension)
        var base = sanitized(newBaseName.trimmingCharacters(in: .whitespacesAndNewlines))
        let typedExtension = ".\(pathExtension)"
        if !pathExtension.isEmpty, base.lowercased().hasSuffix(typedExtension.lowercased()) {
            base = String(base.dropLast(typedExtension.count)).trimmingCharacters(in: .whitespacesAndNewlines)
        }
        guard !base.isEmpty else { return currentFileName }
        return pathExtension.isEmpty ? base : "\(base).\(pathExtension)"
    }
}

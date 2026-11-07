//
//  ManualTitleSuggestion.swift
//  ManualShelf
//

import Foundation

/// Suggests a manual title from the first added file (issue #9).
enum ManualTitleSuggestion {
    /// The title after a file was added: the file name without its extension if this is the
    /// first file and no title has been typed yet; otherwise the current title unchanged.
    static func title(current: String, addedFileName: String, isFirstFile: Bool) -> String {
        guard isFirstFile, current.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return current
        }
        let baseName = (addedFileName as NSString).deletingPathExtension
        return baseName.isEmpty ? current : baseName
    }
}

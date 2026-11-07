//
//  TagColor.swift
//  ManualShelf
//

import SwiftUI

/// Colour of a tag chip, derived from the tag name so that the same tag has the same
/// colour in every view, after every launch and on every device.
struct TagColor: Equatable {
    let background: Color
    let foreground: Color

    // Okabe-Ito palette (colour-blind safe) without black. The text colour is chosen per
    // background so that it reaches at least 4.5:1 contrast.
    static let palette: [TagColor] = [
        TagColor(background: rgb(0x00, 0x72, 0xB2), foreground: .white), // blue, 5.2:1
        TagColor(background: rgb(0xE6, 0x9F, 0x00), foreground: .black), // orange, 9.3:1
        TagColor(background: rgb(0x56, 0xB4, 0xE9), foreground: .black), // sky blue, 9.1:1
        TagColor(background: rgb(0x00, 0x9E, 0x73), foreground: .black), // bluish green, 6.1:1
        TagColor(background: rgb(0xD5, 0x5E, 0x00), foreground: .black), // vermillion, 5.4:1
        TagColor(background: rgb(0xCC, 0x79, 0xA7), foreground: .black), // reddish purple, 6.9:1
        TagColor(background: rgb(0xF0, 0xE4, 0x42), foreground: .black)  // yellow, 15.9:1
    ]

    private static let fnvOffsetBasis: UInt64 = 0xcbf29ce484222325
    private static let fnvPrime: UInt64 = 0x100000001b3

    /// Colour for a tag name; names are compared trimmed and case-insensitively, like
    /// everywhere else in the app.
    static func forName(_ name: String?) -> TagColor {
        palette[paletteIndex(forName: name)]
    }

    /// Palette index from a 64-bit FNV-1a hash of the normalised name's UTF-8 bytes.
    /// Unlike `hashValue`, which is seeded per process, this is stable across launches.
    static func paletteIndex(forName name: String?) -> Int {
        let normalizedName = (name ?? "").trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        var hash = fnvOffsetBasis
        for byte in normalizedName.utf8 {
            hash ^= UInt64(byte)
            hash = hash &* fnvPrime
        }
        return Int(hash % UInt64(palette.count))
    }

    private static func rgb(_ red: Int, _ green: Int, _ blue: Int) -> Color {
        let maxComponent = 255.0
        return Color(red: Double(red) / maxComponent, green: Double(green) / maxComponent, blue: Double(blue) / maxComponent)
    }
}

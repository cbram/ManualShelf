import Foundation

enum SortOption: String, CaseIterable, Identifiable {
    case titleAscending
    case titleDescending
    case dateAddedDescending
    case dateAddedAscending

    var id: String { self.rawValue }

    // Localized name shown in the sort menu
    var title: String {
        switch self {
        case .titleAscending: return String(localized: "Title (A-Z)")
        case .titleDescending: return String(localized: "Title (Z-A)")
        case .dateAddedDescending: return String(localized: "Added (Newest First)")
        case .dateAddedAscending: return String(localized: "Added (Oldest First)")
        }
    }

    var sortDescriptors: [NSSortDescriptor] {
        switch self {
        case .titleAscending:
            return [NSSortDescriptor(keyPath: \Manual.title, ascending: true),
                    NSSortDescriptor(keyPath: \Manual.dateAdded, ascending: false)] // Secondary sort for equal titles
        case .titleDescending:
            return [NSSortDescriptor(keyPath: \Manual.title, ascending: false),
                    NSSortDescriptor(keyPath: \Manual.dateAdded, ascending: false)]
        case .dateAddedDescending:
            return [NSSortDescriptor(keyPath: \Manual.dateAdded, ascending: false),
                    NSSortDescriptor(keyPath: \Manual.title, ascending: true)]
        case .dateAddedAscending:
            return [NSSortDescriptor(keyPath: \Manual.dateAdded, ascending: true),
                    NSSortDescriptor(keyPath: \Manual.title, ascending: true)]
        }
    }
} 
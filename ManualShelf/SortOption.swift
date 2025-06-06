import Foundation

enum SortOption: String, CaseIterable, Identifiable {
    case titleAscending = "Titel (A-Z)"
    case titleDescending = "Titel (Z-A)"
    case dateAddedDescending = "Hinzugefügt (Neueste zuerst)"
    case dateAddedAscending = "Hinzugefügt (Älteste zuerst)"

    var id: String { self.rawValue }

    var sortDescriptors: [NSSortDescriptor] {
        switch self {
        case .titleAscending:
            return [NSSortDescriptor(keyPath: \Manual.title, ascending: true),
                    NSSortDescriptor(keyPath: \Manual.dateAdded, ascending: false)] // Sekundäre Sortierung bei gleichem Titel
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
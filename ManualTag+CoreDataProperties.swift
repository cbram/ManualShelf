//
//  ManualTag+CoreDataProperties.swift
//  ManualShelf
//
//  Created by Christian Bram on 06.06.25.
//
//

import Foundation
import CoreData


extension ManualTag {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<ManualTag> {
        return NSFetchRequest<ManualTag>(entityName: "ManualTag")
    }

    @NSManaged public var color: String?
    @NSManaged public var name: String?
    @NSManaged public var manuals: NSSet?

}

// MARK: Generated accessors for manuals
extension ManualTag {

    @objc(addManualsObject:)
    @NSManaged public func addToManuals(_ value: ManualFile)

    @objc(removeManualsObject:)
    @NSManaged public func removeFromManuals(_ value: ManualFile)

    @objc(addManuals:)
    @NSManaged public func addToManuals(_ values: NSSet)

    @objc(removeManuals:)
    @NSManaged public func removeFromManuals(_ values: NSSet)

}

extension ManualTag: Identifiable {

}

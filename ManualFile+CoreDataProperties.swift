//
//  ManualFile+CoreDataProperties.swift
//  ManualShelf
//
//  Created by Christian Bram on 06.06.25.
//
//

import Foundation
import CoreData


extension ManualFile {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<ManualFile> {
        return NSFetchRequest<ManualFile>(entityName: "ManualFile")
    }

    @NSManaged public var dateAdded: Date?
    @NSManaged public var fileData: Data?
    @NSManaged public var fileName: String?
    @NSManaged public var fileType: String?
    @NSManaged public var imageRotationDegrees: Int16
    @NSManaged public var pdfRotationDegrees: Int16
    @NSManaged public var manual: Manual?
    @NSManaged public var manualTags: NSSet?

}

// MARK: Generated accessors for manualTags
extension ManualFile {

    @objc(addManualTagsObject:)
    @NSManaged public func addToManualTags(_ value: ManualTag)

    @objc(removeManualTagsObject:)
    @NSManaged public func removeFromManualTags(_ value: ManualTag)

    @objc(addManualTags:)
    @NSManaged public func addToManualTags(_ values: NSSet)

    @objc(removeManualTags:)
    @NSManaged public func removeFromManualTags(_ values: NSSet)

}

extension ManualFile : Identifiable {

}

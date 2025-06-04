//
//  Manual+CoreDataProperties.swift
//  
//
//  Created by Christian Bram on 04.06.25.
//
//  This file was automatically generated and should not be edited.
//

import Foundation
import CoreData


extension Manual {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Manual> {
        return NSFetchRequest<Manual>(entityName: "Manual")
    }

    @NSManaged public var title: String?
    @NSManaged public var fileName: String?
    @NSManaged public var dateAdded: Date?
    @NSManaged public var fileData: Data?
    @NSManaged public var fileType: String?
    @NSManaged public var pdfRotationDegrees: Int16

}

extension Manual : Identifiable {

}

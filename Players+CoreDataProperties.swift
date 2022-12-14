//
//  Players+CoreDataProperties.swift
//  Who Buys
//
//  Created by H Steve Silesky on 12/13/16.
//  Copyright © 2016 STEVE SILESKY. All rights reserved.
//

import Foundation
import CoreData


extension Players {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Players> {
        return NSFetchRequest<Players>(entityName: "Players");
    }

    @NSManaged public var checked: Bool
    @NSManaged public var losses: Double
    @NSManaged public var name: String?
    @NSManaged public var wins: Double

}

//
//  User+CoreDataClass.swift
//  HandAndFoot
//
//  Created by Ben Oztalay on 4/14/20.
//  Copyright © 2020 Ben Oztalay. All rights reserved.
//
//

import Foundation
import CoreData

@objc(User)
public class User: NSManagedObject, ModelUpdateable {

    static let entityName = "User"
    
    func update(from json: JSONDictionary) throws {
        // TODO
    }
}

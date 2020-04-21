//
//  UserGame+CoreDataClass.swift
//  HandAndFoot
//
//  Created by Ben Oztalay on 4/14/20.
//  Copyright © 2020 Ben Oztalay. All rights reserved.
//
//

import Foundation
import CoreData

@objc(UserGame)
public class UserGame: NSManagedObject, ModelUpdateable {

    static let entityName = "UserGame"
    
    func update(from json: JSONDictionary) throws {
        // TODO
    }
}

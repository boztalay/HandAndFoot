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
public class User: NSManagedObject, Updateable {

    static func updateOrCreate(from json: JSONDictionary) throws {
        // TODO
    }
    
    func update(from json: JSONDictionary) throws {
        // TODO
    }
}

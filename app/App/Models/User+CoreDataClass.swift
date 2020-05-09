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
        guard let id = json["id"] as? Int,
              let firstName = json["first_name"] as? String,
              let lastName = json["last_name"] as? String,
              let email = json["email"] as? String,
              let createdString = json["created"] as? String,
              let lastUpdatedString = json["last_updated"] as? String else {
            
            throw ModelUpdateError.invalidDictionary
        }

        guard let created = DateFormatter.dateForClient(from: createdString),
              let lastUpdated = DateFormatter.dateForClient(from: lastUpdatedString) else {
            throw ModelUpdateError.invalidDateFromServer
        }
        
        self.id = Int32(id)
        self.firstName = firstName
        self.lastName = lastName
        self.email = email
        self.created = created
        self.lastUpdated = lastUpdated
    }
}

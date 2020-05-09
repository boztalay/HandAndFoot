//
//  GameModel+CoreDataClass.swift
//  HandAndFoot
//
//  Created by Ben Oztalay on 4/14/20.
//  Copyright © 2020 Ben Oztalay. All rights reserved.
//
//

import Foundation
import CoreData

@objc(GameModel)
public class GameModel: NSManagedObject, ModelUpdateable {

    static let entityName = "GameModel"
    
    func update(from json: JSONDictionary) throws {
        guard let id = json["id"] as? Int,
              let initialState = json["initial_state"] as? String,
              let title = json["title"] as? String,
              let currentUserId = json["current_user"] as? Int,
              let createdString = json["created"] as? String,
              let lastUpdatedString = json["last_updated"] as? String else {
            
            throw ModelUpdateError.invalidDictionary
        }

        guard let created = DateFormatter.dateForClient(from: createdString),
              let lastUpdated = DateFormatter.dateForClient(from: lastUpdatedString) else {
            throw ModelUpdateError.invalidDateFromServer
        }
        
        guard let currentUser: User = DataManager.shared.fetchEntity(with: ["id" : currentUserId]) else {
            throw ModelUpdateError.invalidDictionary
        }
        
        self.id = Int32(id)
        self.initialState = initialState
        self.title = title
        self.currentUser = currentUser
        self.created = created
        self.lastUpdated = lastUpdated
    }
}

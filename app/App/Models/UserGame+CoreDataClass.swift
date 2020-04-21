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

enum UserGameRole: String {
    case owner
    case player
}

@objc(UserGame)
public class UserGame: NSManagedObject, ModelUpdateable {

    static let entityName = "UserGame"
    
    var role: UserGameRole {
        return UserGameRole(rawValue: self.roleString!)!
    }
    
    func update(from json: JSONDictionary) throws {
        guard let id = json["id"] as? Int,
              let userId = json["content"] as? Int,
              let gameId = json["game"] as? Int,
              let roleString = json["role"] as? String,
              let userAccepted = json["user_accepted"] as? Bool else {
            
            throw ModelUpdateError.invalidDictionary
        }

        guard let user: User = DataManager.shared.fetchEntity(with: ["id" : userId]) else {
            throw ModelUpdateError.invalidDictionary
        }
        
        guard let game: GameModel = DataManager.shared.fetchEntity(with: ["id" : gameId]) else {
            throw ModelUpdateError.invalidDictionary
        }
        
        guard let role = UserGameRole(rawValue: roleString) else {
            throw ModelUpdateError.invalidDictionary
        }
        
        self.id = Int32(id)
        self.user = user
        self.game = game
        self.roleString = role.rawValue
        self.userAccepted = userAccepted
    }
}

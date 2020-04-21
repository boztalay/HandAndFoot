//
//  ActionModel+CoreDataClass.swift
//  HandAndFoot
//
//  Created by Ben Oztalay on 4/14/20.
//  Copyright © 2020 Ben Oztalay. All rights reserved.
//
//

import Foundation
import CoreData

@objc(ActionModel)
public class ActionModel: NSManagedObject, ModelUpdateable {

    static let entityName = "ActionModel"
    
    func update(from json: JSONDictionary) throws {
        guard let id = json["id"] as? Int,
              let content = json["content"] as? String,
              let createdString = json["created"] as? String,
              let gameId = json["game"] as? Int else {
            
            throw ModelUpdateError.invalidDictionary
        }

        guard let created = DateFormatter.dateForClient(from: createdString) else {
            throw ModelUpdateError.invalidDateFromServer
        }
        
        guard let game: GameModel = DataManager.shared.fetchEntity(with: ["id" : gameId]) else {
            throw ModelUpdateError.invalidDictionary
        }
        
        self.id = Int32(id)
        self.content = content
        self.created = created
        self.game = game
    }
}

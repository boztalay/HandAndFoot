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
        
        self.id = Int32(id)
        self.content = content
        // TODO
        // self.game = GameModel.fetch(withId: gameId)!
        // self.created = some fancy extension of DateFormatter to suit our needs
    }
}

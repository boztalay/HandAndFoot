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
public class ActionModel: NSManagedObject, Updateable {

    static func updateOrCreate(from json: JSONDictionary) throws {
        guard let id = json["id"] as? Int else {
            throw UpdateError.invalidDictionary
        }
        
        let fetchRequest = NSFetchRequest<ActionModel>(entityName: "ActionModel")
        fetchRequest.predicate = NSPredicate(format: "id == %@", id)
        
        let results = try AppDelegate.shared.persistentContainer.viewContext.fetch(fetchRequest)
        
        if results.count == 0 {
            let actionModel = NSEntityDescription.insertNewObject(forEntityName: "ActionModel", into: AppDelegate.shared.persistentContainer.viewContext) as! ActionModel
            try actionModel.update(from: json)
        } else if results.count == 1 {
            let actionModel = results.first!
            try actionModel.update(from: json)
        } else {
            throw UpdateError.foundTooManyObjects
        }
    }
    
    func update(from json: JSONDictionary) throws {
        guard let id = json["id"] as? Int,
              let content = json["content"] as? String,
              let createdString = json["created"] as? String,
              let gameId = json["game"] as? Int else {
            
            throw UpdateError.invalidDictionary
        }
        
        self.id = Int32(id)
        self.content = content
        // TODO
        // self.game = GameModel.fetch(withId: gameId)!
        // self.created = some fancy extension of DateFormatter to suit our needs
    }
}

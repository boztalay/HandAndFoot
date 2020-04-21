//
//  DataManager.swift
//  HandAndFoot
//
//  Created by Ben Oztalay on 4/17/20.
//  Copyright © 2020 Ben Oztalay. All rights reserved.
//

import Foundation
import CoreData

typealias DataManagerSyncCallback = (Bool) -> ()

class DataManager {
    
    static let shared = DataManager()

    lazy private var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "HandAndFoot")
        container.loadPersistentStores() { (storeDescription, error) in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        }

        return container
    }()
    
    func fetchEntity<T: ModelUpdateable>(with json: JSONDictionary) -> T?  {
        guard let id = json["id"] as? Int else {
            return nil
        }
        
        let fetchRequest = NSFetchRequest<T>(entityName: T.entityName)
        fetchRequest.predicate = NSPredicate(format: "id == %@", id)
        
        let results: [T]
        do {
            results = try self.persistentContainer.viewContext.fetch(fetchRequest)
        } catch {
            return nil
        }
        
        if results.count == 0 {
            return NSEntityDescription.insertNewObject(forEntityName: T.entityName, into: self.persistentContainer.viewContext) as? T
        } else if results.count == 1 {
            return results.first!
        } else {
            return nil
        }
    }
    
    func sync(callback: @escaping DataManagerSyncCallback) {
        Network.shared.sendSyncRequest() { (success, httpStatusCode, response) in
            guard success else {
                callback(false)
                return
            }
            
            guard let response = response else {
                callback(false)
                return
            }
            
            guard let gameJsons = response["games"] as? [JSONDictionary],
                  let usergameJsons = response["usergames"] as? [JSONDictionary],
                  let actionJsons = response["actions"] as? [JSONDictionary],
                  let userJsons = response["users"] as? [JSONDictionary] else {

                callback(false)
                return
            }
            
            do {
                for gameJson in gameJsons {
                    try GameModel.updateOrCreate(from: gameJson)
                }
                
                for usergameJson in usergameJsons {
                    try UserGame.updateOrCreate(from: usergameJson)
                }
                
                for actionJson in actionJsons {
                    try ActionModel.updateOrCreate(from: actionJson)
                }
                
                for userJson in userJsons {
                    try User.updateOrCreate(from: userJson)
                }
            } catch {
                callback(false)
                return
            }
            
            self.saveContext()
            callback(true)
        }
    }
    
    func saveContext() {
        let context = self.persistentContainer.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                let nserror = error as NSError
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }
}

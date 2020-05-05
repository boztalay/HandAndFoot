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
    private static let firstSyncDate = Date(timeIntervalSince1970: 0)
    
    var currentUser: User? {
        guard let userEmail = UserDefaults.standard.string(forKey: "currentUserEmail") else {
            return nil
        }
        
        return self.fetchUser(with: userEmail)
    }
    
    func setCurrentUser(with email: String) {
        UserDefaults.standard.set(email, forKey: "currentUserEmail")
    }
    
    private var lastUpdated: Date? {
        get {
            guard let object = UserDefaults.standard.object(forKey: "lastUpdated") else {
                return nil
            }
            
            return (object as! Date)
        }
        set(date) {
            UserDefaults.standard.set(date, forKey: "lastUpdated")
        }
    }

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
        fetchRequest.predicate = NSPredicate(format: "id == %d", id)
        
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
    
    private func fetchUser(with email: String) -> User? {
        let fetchRequest = NSFetchRequest<User>(entityName: User.entityName)
        fetchRequest.predicate = NSPredicate(format: "email == %@", email)
        
        let results: [User]
        do {
            results = try self.persistentContainer.viewContext.fetch(fetchRequest)
        } catch {
            return nil
        }
        
        if results.count == 0 {
            return nil
        } else if results.count == 1 {
            return results.first!
        } else {
            fatalError("Found more than one User with the same email")
        }
    }
    
    func fetchEntities<T: ModelUpdateable>(sortedBy sortKey: String? = nil, ascending: Bool = false) -> [T]? {
        let fetchRequest = NSFetchRequest<T>(entityName: T.entityName)
        
        if let sortKey = sortKey {
            fetchRequest.sortDescriptors = [
                NSSortDescriptor(key: sortKey, ascending: ascending)
            ]
        }
        
        let results: [T]
        do {
            results = try self.persistentContainer.viewContext.fetch(fetchRequest)
        } catch {
            return nil
        }
        
        return results
    }
    
    func sync(callback: @escaping DataManagerSyncCallback) {
        let syncDate: Date
        if self.lastUpdated != nil {
            syncDate = self.lastUpdated!
        } else {
            syncDate = DataManager.firstSyncDate
        }
        
        Network.shared.sendSyncRequest(lastUpdated: syncDate) { (success, httpStatusCode, response) in
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

                for userJson in userJsons {
                    try User.updateOrCreate(from: userJson)
                }
                
                for usergameJson in usergameJsons {
                    try UserGame.updateOrCreate(from: usergameJson)
                }
                
                for actionJson in actionJsons {
                    try ActionModel.updateOrCreate(from: actionJson)
                }
            } catch {
                callback(false)
                return
            }
            
            self.saveContext()
            self.lastUpdated = Date()
            
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

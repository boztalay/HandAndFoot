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
    
    private enum Keys: String {
        case token
        case currentUserEmail
        case lastUpdated
    }

    private static let firstSyncDate = Date(timeIntervalSince1970: 0)
    
    static let shared = DataManager()
    
    private var strongbox: Strongbox
    private(set) var token: String?
    
    init() {
        self.strongbox = Strongbox()
        
        if let token = self.strongbox.unarchive(objectForKey: Keys.token.rawValue) as? String {
            self.token = token
        }
    }
    
    var currentUser: User? {
        guard let userEmail = UserDefaults.standard.string(forKey: Keys.currentUserEmail.rawValue) else {
            return nil
        }
        
        return self.fetchUser(with: userEmail)
    }
    
    func setCurrentUser(with email: String) {
        UserDefaults.standard.set(email, forKey: Keys.currentUserEmail.rawValue)
    }
    
    func clearLocalData() {
        UserDefaults.standard.removeObject(forKey: Keys.currentUserEmail.rawValue)
        UserDefaults.standard.removeObject(forKey: Keys.lastUpdated.rawValue)
        self.strongbox.remove(key: Keys.token.rawValue)
        self.deleteAllCoreData()
    }
    
    func setToken(_ token: String) {
        self.token = token

        if !self.strongbox.archive(self.token, key: Keys.token.rawValue) {
            fatalError("Couldn't archive token")
        }
    }
    
    private var lastUpdated: Date? {
        get {
            guard let object = UserDefaults.standard.object(forKey: Keys.lastUpdated.rawValue) else {
                return nil
            }
            
            return (object as! Date)
        }
        set(date) {
            UserDefaults.standard.set(date, forKey: Keys.lastUpdated.rawValue)
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
    
    func createEntity<T: ModelUpdateable>() -> T? {
        return NSEntityDescription.insertNewObject(forEntityName: T.entityName, into: self.persistentContainer.viewContext) as? T
    }
    
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
        
        if results.count == 1 {
            return results.first!
        } else {
            return nil
        }
    }
    
    func fetchUser(with email: String) -> User? {
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
    
    func fetchUserGames(of game: GameModel) -> [UserGame]? {
        let fetchRequest = NSFetchRequest<UserGame>(entityName: UserGame.entityName)
        fetchRequest.predicate = NSPredicate(format: "game == %@", game)
        fetchRequest.sortDescriptors = [
            NSSortDescriptor(key: "id", ascending: true)
        ]
        
        let results: [UserGame]
        do {
            results = try self.persistentContainer.viewContext.fetch(fetchRequest)
        } catch {
            return nil
        }
        
        return results
    }
    
    func fetchActions(of game: GameModel) -> [ActionModel]? {
        let fetchRequest = NSFetchRequest<ActionModel>(entityName: ActionModel.entityName)
        fetchRequest.predicate = NSPredicate(format: "game == %@", game)
        fetchRequest.sortDescriptors = [
            NSSortDescriptor(key: "created", ascending: true)
        ]
        
        let results: [ActionModel]
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
                  let userJsons = response["users"] as? [JSONDictionary],
                  let serverSyncTimeString = response["server_sync_time"] as? String else {

                callback(false)
                return
            }
            
            do {
                for userJson in userJsons {
                    try User.updateOrCreate(from: userJson)
                }
                
                for gameJson in gameJsons {
                    try GameModel.updateOrCreate(from: gameJson)
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
            
            guard let serverSyncTime = DateFormatter.dateForClient(from: serverSyncTimeString) else {
                callback(false)
                return
            }
            
            self.saveContext()
            self.lastUpdated = serverSyncTime
            
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
    
    private func deleteAllCoreData() {
        self.deleteAllObjects(of: ActionModel.self)
        self.deleteAllObjects(of: GameModel.self)
        self.deleteAllObjects(of: User.self)
        self.deleteAllObjects(of: UserGame.self)
    }
    
    private func deleteAllObjects<T: ModelUpdateable>(of entityType: T.Type) {
        let context = self.persistentContainer.viewContext
        
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: T.entityName)
        fetchRequest.returnsObjectsAsFaults = false

        do {
            let results = try context.fetch(fetchRequest)
            for object in results {
                guard let objectData = object as? NSManagedObject else {continue}
                context.delete(objectData)
            }

            try context.save()
        } catch let error {
            fatalError("Couldn't delete all objects of \(T.entityName): \(error)")
        }
    }
}

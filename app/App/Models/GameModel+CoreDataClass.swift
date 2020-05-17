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
    
    var game: Game?
    
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
    
    func loadGame() {
        guard let userGames = DataManager.shared.fetchUserGames(of: self) else {
            fatalError("AAAHHH")
        }
        
        let playerNames = userGames.map() { $0.user!.email! }
        
        let initialStateJson = try! JSONSerialization.jsonObject(with: self.initialState!.data(using: .utf8)!, options: []) as! JSONDictionary
        let decksJson = initialStateJson["decks"] as! JSONDictionary
        let decks = [
            Round.ninety: Deck(with: decksJson[Round.ninety.rawValue] as! JSONDictionary)!,
            Round.oneTwenty: Deck(with: decksJson[Round.oneTwenty.rawValue] as! JSONDictionary)!,
            Round.oneFifty: Deck(with: decksJson[Round.oneFifty.rawValue] as! JSONDictionary)!,
            Round.oneEighty: Deck(with: decksJson[Round.oneEighty.rawValue] as! JSONDictionary)!
        ]

        guard let actionModels = DataManager.shared.fetchActions(of: self) else {
            fatalError("OH NOOOO")
        }
        
        let actions = actionModels.map() { Action(with: $0.contentJson)! }

        self.game = try! Game(playerNames: playerNames, decks: decks)
        for action in actions {
            try! self.game!.apply(action: action)
        }
    }
    
    func user(with email: String) -> User? {
        let matchingUsergames = self.usergames!.filter() { ($0 as! UserGame).user!.email == email }
        guard matchingUsergames.count == 1 else {
            return nil
        }
        
        let usergame = matchingUsergames.first! as! UserGame
        return usergame.user!
    }
}

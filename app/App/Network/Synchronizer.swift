//
//  Synchronizer.swift
//  HandAndFoot
//
//  Created by Ben Oztalay on 4/17/20.
//  Copyright © 2020 Ben Oztalay. All rights reserved.
//

import Foundation

typealias SynchronizerCallback = (Bool) -> ()

class Synchronizer {
    
    static let shared = Synchronizer()
    
    func sync(callback: @escaping SynchronizerCallback) {
        Network.shared.sendSyncRequest() { success, httpStatusCode, response in
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
            
            callback(true)
        }
    }
}

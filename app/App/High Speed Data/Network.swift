//
//  Network.swift
//  HandAndFoot
//
//  Created by Ben Oztalay on 4/14/20.
//  Copyright © 2020 Ben Oztalay. All rights reserved.
//

import Foundation
import PusherSwift

typealias NetworkResponseHandler = (Bool, Int?, JSONDictionary?) -> ()

class Network: PusherDelegate {
    
    private static let baseUrl = URL(string: "https://handandfoot-boztalay.structure.sh")!
    
    static let shared = Network()
    
    private var pusher: Pusher
    
    init() {
        self.pusher = Pusher(
            key: Secrets.pusherKey,
            options: PusherClientOptions(host: .cluster("us2"))
        )

        self.pusher.delegate = self
        self.pusher.subscribe("sync").bind(eventName: "sync") { (event: PusherEvent) in
            self.pusherSyncEventHappened()
        }

        self.pusher.connect()
    }
    
    func pusherSyncEventHappened() {
        // TODO
    }
    
    func sendLoginRequest(email: String, password: String, responseHandler: @escaping NetworkResponseHandler) {
        self.sendRequest(
            path: "/api/login",
            payload: [
                "email" : email,
                "password" : password
            ],
            responseHandler: self.loginResponseHandler(originalResponseHandler: responseHandler)
        )
    }
    
    func sendSignUpRequest(name: String, email: String, password: String, responseHandler: @escaping NetworkResponseHandler) {
        self.sendRequest(
            path: "/api/signup",
            payload: [
                "name": name,
                "email" : email,
                "password" : password
            ],
            responseHandler: self.loginResponseHandler(originalResponseHandler: responseHandler)
        )
    }
    
    private func loginResponseHandler(originalResponseHandler: @escaping NetworkResponseHandler) -> NetworkResponseHandler {
        return { (success, httpStatusCode, response) in
            if success, let token = response?["token"] as? String {
                DataManager.shared.setToken(token)
            }
            
            originalResponseHandler(success, httpStatusCode, response)
        }
    }
    
    func sendLogoutRequest(responseHandler: @escaping NetworkResponseHandler) {
        guard DataManager.shared.token != nil else {
            responseHandler(false, nil, nil)
            return
        }

        self.sendRequest(
            path: "/api/logout",
            payload: [:],
            responseHandler: responseHandler
        )
    }
    
    func sendCreateGameRequest(title: String, userEmails: [String], responseHandler: @escaping NetworkResponseHandler) {
        guard DataManager.shared.token != nil else {
            responseHandler(false, nil, nil)
            return
        }
        
        self.sendRequest(
            path: "/api/game/create",
            payload: [
                "title" : title,
                "users" : userEmails
            ],
            responseHandler: responseHandler
        )
    }
    
    func sendSyncRequest(lastUpdated: Date, responseHandler: @escaping NetworkResponseHandler) {
        guard DataManager.shared.token != nil else {
            responseHandler(false, nil, nil)
            return
        }
        
        self.sendRequest(
            path: "/api/sync",
            payload: [
                "last_updated" : DateFormatter.stringForServer(from: lastUpdated)
            ],
            responseHandler: responseHandler
        )
    }
    
    func sendUserSearchRequest(searchTerm: String, responseHandler: @escaping NetworkResponseHandler) {
        guard DataManager.shared.token != nil else {
            responseHandler(false, nil, nil)
            return
        }
        
        self.sendRequest(
            path: "/api/user/search",
            payload: [
                "search_term" : searchTerm
            ],
            responseHandler: responseHandler
        )
    }
    
    func sendAddActionRequest(game: GameModel, action: Action, responseHandler: @escaping NetworkResponseHandler) {
        guard DataManager.shared.token != nil else {
            responseHandler(false, nil, nil)
            return
        }
        
        self.sendRequest(
            path: "/api/game/add_action",
            payload: [
                "game": game.id,
                "action": action.toJSON()
            ],
            responseHandler: responseHandler
        )
    }
    
    private func sendRequest(path: String, payload: JSONDictionary, responseHandler: @escaping NetworkResponseHandler) {
        let url = Network.baseUrl.appendingPathComponent(path)
        var urlRequest = URLRequest(url: url)
        
        urlRequest.httpMethod = "POST"
        urlRequest.httpBody = try! JSONSerialization.data(withJSONObject: payload, options: [])
        urlRequest.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if let token = DataManager.shared.token {
            urlRequest.addValue(token, forHTTPHeaderField: "X-App-Token")
        }

        let task = URLSession.shared.dataTask(with: urlRequest) { (data, response, error) in
            DispatchQueue.main.async {
                if error != nil {
                    responseHandler(false, nil, nil)
                    return
                }
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    responseHandler(false, nil, nil)
                    return
                }
                
                guard let data = data else {
                    responseHandler(false, httpResponse.statusCode, nil)
                    return
                }
                
                guard let jsonResponse = try? JSONSerialization.jsonObject(with: data, options: []) as? JSONDictionary else {
                    responseHandler(false, httpResponse.statusCode, nil)
                    return
                }
                
                guard let success = jsonResponse["success"] as? Bool else {
                    responseHandler(false, httpResponse.statusCode, jsonResponse)
                    return
                }

                responseHandler(success, httpResponse.statusCode, jsonResponse)
            }
        }

        task.resume()
    }
}

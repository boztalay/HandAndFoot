//
//  Network.swift
//  HandAndFoot
//
//  Created by Ben Oztalay on 4/14/20.
//  Copyright © 2020 Ben Oztalay. All rights reserved.
//

import Foundation

typealias NetworkResponseHandler = (Bool, Int?, JSONDictionary?) -> ()

class Network {
    
    private static let baseUrl = URL(string: "https://handandfoot-boztalay.structure.sh")!
    private static let tokenArchiveKey = "token"
    
    static let shared = Network()
    
    var token: String?
    var strongbox: Strongbox
    
    init() {
        self.strongbox = Strongbox()
        
        if let token = self.strongbox.unarchive(objectForKey: Network.tokenArchiveKey) as? String {
            self.token = token
        }
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
    
    func sendSyncRequest(lastUpdated: Date, responseHandler: @escaping NetworkResponseHandler) {
        guard self.token != nil else {
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
    
    private func loginResponseHandler(originalResponseHandler: @escaping NetworkResponseHandler) -> NetworkResponseHandler {
        return { (success, httpStatusCode, response) in
            if success, let token = response?["token"] as? String {
                self.token = token
                if !self.strongbox.archive(self.token, key: Network.tokenArchiveKey) {
                    fatalError("Couldn't archive token")
                }
            }
            
            originalResponseHandler(success, httpStatusCode, response)
        }
    }
    
    private func sendRequest(path: String, payload: JSONDictionary, responseHandler: @escaping NetworkResponseHandler) {
        let url = Network.baseUrl.appendingPathComponent(path)
        var urlRequest = URLRequest(url: url)
        
        urlRequest.httpMethod = "POST"
        urlRequest.httpBody = try! JSONSerialization.data(withJSONObject: payload, options: [])
        urlRequest.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if let token = self.token {
            urlRequest.addValue(token, forHTTPHeaderField: "X-App-Token")
        }

        let task = URLSession.shared.dataTask(with: urlRequest) { (data, response, error) in
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

            DispatchQueue.main.async {
                responseHandler(success, httpResponse.statusCode, jsonResponse)
            }
        }

        task.resume()
    }
}

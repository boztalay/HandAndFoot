//
//  BaseModel.swift
//  HandAndFoot
//
//  Created by Ben Oztalay on 4/17/20.
//  Copyright © 2020 Ben Oztalay. All rights reserved.
//

import Foundation

enum UpdateError: Error {
    case invalidDictionary
    case foundTooManyObjects
}

protocol Updateable {
    static func updateOrCreate(from json: JSONDictionary) throws
    func update(from json: JSONDictionary) throws
}

//
//  JSONCodable.swift
//  HandAndFoot
//
//  Created by Ben Oztalay on 3/28/20.
//  Copyright © 2020 Ben Oztalay. All rights reserved.
//

import Foundation

typealias JSONDictionary = [String: Any]

protocol JSONDecodable {
    init?(with json: JSONDictionary)
}

protocol JSONEncodable {
    func toJSON() -> JSONDictionary
}

typealias JSONCodable = JSONDecodable & JSONEncodable

//
//  ModelUpdateable.swift
//  HandAndFoot
//
//  Created by Ben Oztalay on 4/17/20.
//  Copyright © 2020 Ben Oztalay. All rights reserved.
//

import Foundation
import CoreData

enum ModelUpdateError: Error {
    case couldNotFindOrCreateEntity
    case invalidDictionary
    case invalidDateFromServer
}

protocol ModelUpdateable: NSManagedObject {
    static var entityName: String { get }
    func update(from json: JSONDictionary) throws
}

extension ModelUpdateable {

    static func updateOrCreate(from json: JSONDictionary) throws {
        guard let entity: Self = DataManager.shared.fetchEntity(with: json) else {
            throw ModelUpdateError.couldNotFindOrCreateEntity
        }
        
        try entity.update(from: json)
    }
}

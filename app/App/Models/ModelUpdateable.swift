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
        var entity: Self

        if let existingEntity: Self = DataManager.shared.fetchEntity(with: json) {
            entity = existingEntity
        } else {
            guard let newEntity: Self = DataManager.shared.createEntity() else {
                throw ModelUpdateError.couldNotFindOrCreateEntity
            }
            entity = newEntity
        }
        
        try entity.update(from: json)
    }
}

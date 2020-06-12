//
//  DraggableDroppable.swift
//  HandAndFoot
//
//  Created by Ben Oztalay on 6/12/20.
//  Copyright © 2020 Ben Oztalay. All rights reserved.
//

import Foundation

enum DragDropSite: Hashable {
    case deck
    case discardPile
    case book(CardRank?)
    case hand
    
    static var allCases: Set<DragDropSite> {
        var cases = Set<DragDropSite>()
        
        cases.insert(.deck)
        cases.insert(.discardPile)
        cases.insert(.hand)
        
        let bookableRanks = CardRank.allCases.filter({ $0.bookRank != nil })
        for rank in bookableRanks {
            cases.insert(.book(rank))
        }
        
        return cases
    }
}

protocol DragDelegate: AnyObject {
    func dragStarted(from source: DragDropSite, with cards: [Card])
}

protocol Draggable: AnyObject {
    var dragDelegate: DragDelegate? { get set }

    func activateDragging(for source: DragDropSite)
    func deactivateDragging(for source: DragDropSite)
    func dragDone()
}

protocol Droppable: AnyObject {
    func activateDropping(for destination: DragDropSite)
    func deactivateDropping(for destination: DragDropSite)
}

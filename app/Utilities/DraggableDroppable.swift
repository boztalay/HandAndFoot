//
//  DraggableDroppable.swift
//  HandAndFoot
//
//  Created by Ben Oztalay on 6/12/20.
//  Copyright © 2020 Ben Oztalay. All rights reserved.
//

import Foundation
import UIKit

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
    func dragStartedFaceDown(_ source: DragDropSite, with point: CGPoint, and cardSize: CGSize)
    func dragStarted(_ source: DragDropSite, with cards: [(Card, CGPoint)], and cardSize: CGSize)
    func dragMoved(_ source: DragDropSite, to point: CGPoint)
    func dragEnded(_ source: DragDropSite, at point: CGPoint)
}

protocol Draggable: UIView {
    var dragDelegate: DragDelegate? { get set }

    func activateDragging()
    func setCardsDragged(_ cards: [Card])
}

protocol Droppable: UIView {
    func activateDropping()
    func setCardsDropped(_ cards: [Card])
}

//
//  Errors.swift
//  HandAndFoot
//
//  Created by Ben Oztalay on 3/26/20.
//  Copyright © 2020 Ben Oztalay. All rights reserved.
//

enum IllegalActionError: Error {
    case cardDoesntMatchBookRank
    case notEnoughCardsToStartBook
    case cannotStartBookWithGivenCards
    case tooManyWildsInBookToAddAnother
    case initialHandOrFootNotSizedCorrectly
    case deckIsEmpty
    case discardPileIsEmpty
    case notEnoughPointsToLayDown
    case playerDoesntHaveBook
    case cardNotInHand
    case bookAlreadyExists
    case cannotDrawFromTheDeck
    case cannotDrawFromTheDiscardPile
    case notYourTurn
    case alreadyLaidDownThisRound
    case cannotGoOut
    case cannotEndTurnYet
    case unknownPlayer
    case gameIsOver
}

enum IllegalSetupError: Error {
    case tooFewPlayers
    case tooManyPlayers
}

//
//  main.swift
//  HandAndFootEngine
//
//  Created by Ben Oztalay on 3/26/20.
//  Copyright © 2020 Ben Oztalay. All rights reserved.
//

import Foundation

guard CommandLine.arguments.count != 2 else {
    fatalError("Exactly one argument expected, the path to the test case to run")
}

let testCaseFilePath = CommandLine.arguments[1]
guard let testCaseFileContents = FileManager.default.contents(atPath: testCaseFilePath) else {
    fatalError("Couldn't read the given test case file")
}

guard let testCase = try? JSONSerialization.jsonObject(with: testCaseFileContents, options: []) as? [String : Any] else {
    fatalError("Couldn't decode a JSON dictionary from the given test case file")
}

let playerNames = testCase["players"] as! [String]
let initialDeckJson = testCase["initial_deck"] as! [String : String]
let actionsJson = testCase["actions"] as! [String : String]

// TODO
// - JSONCodable all the things
// - Construct the deck from the initial deck state in the JSON
// - Construct a Game with the deck and player names
// - Construct all of the actions from the actions in the JSON
// - Run through all of the actions, stopping if there's a problem
// - Print out the state of the Game in JSON

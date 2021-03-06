//
//  main.swift
//  HandAndFootEngine
//
//  Created by Ben Oztalay on 3/26/20.
//  Copyright © 2020 Ben Oztalay. All rights reserved.
//

import Foundation

import func Darwin.fputs
import var Darwin.stderr

struct StderrOutputStream: TextOutputStream {
    mutating func write(_ string: String) {
        fputs(string, stderr)
    }
}

var standardError = StderrOutputStream()

guard CommandLine.arguments.count == 2 else {
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
let actionsJson = testCase["actions"] as! [JSONDictionary]

let decks: [Round : Deck] = [
    .ninety : Deck(with: testCase["ninety_deck"] as! JSONDictionary)!,
    .oneTwenty : Deck(with: testCase["one_twenty_deck"] as! JSONDictionary)!,
    .oneFifty : Deck(with: testCase["one_fifty_deck"] as! JSONDictionary)!,
    .oneEighty : Deck(with: testCase["one_eighty_deck"] as! JSONDictionary)!
]

let game = try! Game(playerNames: playerNames, decks: decks)

var actions = actionsJson.map({ Action(with: $0)! })
for action in actions {
    do {
        try game.apply(action: action)
    } catch let actionError as IllegalActionError {
        print("IllegalActionError: \(actionError)", to: &standardError)
        break
    } catch {
        fatalError("Unknown error applying an action")
        break
    }
}

let jsonData = try JSONSerialization.data(withJSONObject: game.toJSON(), options: [.prettyPrinted])
print(String(data: jsonData, encoding: .utf8)!)

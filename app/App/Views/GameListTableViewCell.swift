//
//  GameListTableViewCell.swift
//  HandAndFoot
//
//  Created by Ben Oztalay on 5/5/20.
//  Copyright © 2020 Ben Oztalay. All rights reserved.
//

import UIKit

class GameListTableViewCell: UITableViewCell {
    
    static let reuseIdentifier = "GameListTableViewCell"

    var gameIdLabel: UILabel
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        self.gameIdLabel = UILabel()
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        self.addSubview(self.gameIdLabel)
        self.gameIdLabel.pin(to: self)
    }

    func setGame(_ game: GameModel) {
        self.gameIdLabel.text = "\(game.id)"
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

//
//  GamePreviewView.swift
//  HandAndFoot
//
//  Created by Ben Oztalay on 4/28/20.
//  Copyright © 2020 Ben Oztalay. All rights reserved.
//

import UIKit

class GamePreviewView: UIView {

    var titleLabel: UILabel!
    var turnLabel: UILabel!
    var playButton: UIButton!
    var scoreBoardStackView: UIStackView!

    init() {
        super.init(frame: CGRect.zero)
        
        self.titleLabel = UILabel()
        self.turnLabel = UILabel()
        self.scoreBoardStackView = UIStackView()
        self.playButton = UIButton(type: .system)
    }
    
    func setGame(_ game: GameModel) {
        self.titleLabel.removeFromSuperview()
        self.addSubview(self.titleLabel)
        self.titleLabel.centerHorizontally(in: self)
        self.titleLabel.pin(edge: .top, to: .top, of: self, with: 10)
        self.titleLabel.text = game.title
        
        self.turnLabel.removeFromSuperview()
        self.addSubview(self.turnLabel)
        self.turnLabel.centerHorizontally(in: self)
        self.turnLabel.pin(edge: .top, to: .bottom, of: self.titleLabel, with: 10)
        self.turnLabel.text = "\(game.currentUser!.firstName!)'s turn"
        
        self.scoreBoardStackView.removeFromSuperview()
        self.addSubview(self.scoreBoardStackView)
        self.scoreBoardStackView.pinX(to: self, leading: 10, trailing: 10)
        self.scoreBoardStackView.pin(edge: .top, to: .bottom, of: self.turnLabel, with: 10)
        
        self.playButton.removeFromSuperview()
        self.addSubview(self.playButton)
        self.playButton.centerHorizontally(in: self)
        self.playButton.pin(edge: .top, to: .bottom, of: self.scoreBoardStackView, with: 10)
        self.playButton.pin(edge: .bottom, to: .bottom, of: self, with: -10)
        self.playButton.setTitle("Play!", for: .normal)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

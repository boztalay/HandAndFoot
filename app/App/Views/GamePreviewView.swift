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
    var scoreBoardView: ScoreBoardView!

    init() {
        super.init(frame: CGRect.zero)
        
        self.titleLabel = UILabel()
        self.turnLabel = UILabel()
        self.scoreBoardView = ScoreBoardView()
        self.playButton = UIButton(type: .system)
    }
    
    func setGameModel(_ gameModel: GameModel) {
        if gameModel.game == nil {
            gameModel.loadGame()
        }
        
        self.titleLabel.removeFromSuperview()
        self.addSubview(self.titleLabel)
        self.titleLabel.centerHorizontally(in: self)
        self.titleLabel.pin(edge: .top, to: .top, of: self, with: 20)
        self.titleLabel.font = UIFont.boldSystemFont(ofSize: 24.0)
        self.titleLabel.text = gameModel.title
        
        self.turnLabel.removeFromSuperview()
        self.addSubview(self.turnLabel)
        self.turnLabel.centerHorizontally(in: self)
        self.turnLabel.pin(edge: .top, to: .bottom, of: self.titleLabel, with: 10)
        self.turnLabel.text = "It's \(gameModel.currentUser!.firstName!)'s turn"
        
        self.playButton.removeFromSuperview()
        self.addSubview(self.playButton)
        self.playButton.centerHorizontally(in: self)
        self.playButton.pin(edge: .top, to: .bottom, of: self.turnLabel, with: 20)
        self.playButton.setTitle("Play!", for: .normal)
        
        self.scoreBoardView.removeFromSuperview()
        self.addSubview(self.scoreBoardView)
        self.scoreBoardView.pinX(to: self, leading: 100, trailing: -100)
        self.scoreBoardView.pin(edge: .top, to: .bottom, of: self.playButton, with: 50)
        self.scoreBoardView.update(with: gameModel)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

//
//  GameViewController.swift
//  HandAndFoot
//
//  Created by Ben Oztalay on 5/20/20.
//  Copyright © 2020 Ben Oztalay. All rights reserved.
//

import UIKit

class GameViewController: UIViewController {
    
    private var handView: HandView!
    
    private var game: GameModel!
    
    init(game: GameModel) {
        super.init(nibName: nil, bundle: nil)

        self.handView = HandView()
        
        self.game = game
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = .white
        
        self.title = self.game.title!
        
        let game = self.game.game!
        let player = game.getPlayer(named: DataManager.shared.currentUser!.email!)!
        
        self.view.addSubview(self.handView)
        self.handView.pinX(to: self.view, leading: 40, trailing: -40)
        self.handView.pin(edge: .bottom, to: .bottom, of: self.view, with: -40)
        self.handView.pinHeight(toHeightOf: self.view, multiplier: 0.2, constant: 0.0)
        
        self.handView.update(cards: player.hand)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

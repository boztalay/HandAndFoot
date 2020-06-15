//
//  OpponentPreviewView.swift
//  HandAndFoot
//
//  Created by Ben Oztalay on 5/25/20.
//  Copyright © 2020 Ben Oztalay. All rights reserved.
//

import UIKit

protocol OpponentPreviewViewDelegate: AnyObject {
    func opponentPreviewViewTapped(player: Player)
}

class OpponentPreviewView: UIView {

    private var circleView: UIView!
    private var nameLabel: UILabel!
    private var inFootBadge: UILabel!
    private var hasNaturalBadge: UILabel!
    private var hasUnnaturalBadge: UILabel!
    
    private var player: Player?
    private var tapGestureRecognizer: UITapGestureRecognizer!
    
    weak var delegate: OpponentPreviewViewDelegate?
    
    var isSelected: Bool {
        get {
            return (self.circleView.layer.borderColor == UIColor.systemRed.cgColor)
        }
        set {
            if newValue {
                self.circleView.layer.borderColor = UIColor.systemRed.cgColor
            } else {
                self.circleView.layer.borderColor = UIColor.black.cgColor
            }
        }
    }
    
    init() {
        super.init(frame: .zero)
        
        self.circleView = UIView()
        self.addSubview(self.circleView)
        self.circleView.pin(to: self)
        self.circleView.backgroundColor = .white
        self.circleView.layer.borderWidth = 1
        self.circleView.layer.borderColor = UIColor.black.cgColor
        
        self.nameLabel = UILabel()
        self.addSubview(self.nameLabel)
        self.nameLabel.centerHorizontally(in: self)
        self.nameLabel.centerVertically(in: self)
        self.nameLabel.pinWidth(toWidthOf: self, multiplier: 0.95, constant: 0.0)
        self.nameLabel.textAlignment = .center
        self.nameLabel.adjustsFontSizeToFitWidth = true
        
        self.inFootBadge = UILabel()
        self.addSubview(self.inFootBadge)
        self.inFootBadge.pin(edge: .leading, to: .leading, of: self)
        self.inFootBadge.pin(edge: .bottom, to: .bottom, of: self, with: 5.0)
        self.inFootBadge.pinWidth(toWidthOf: self, multiplier: 0.3, constant: 0.0)
        self.inFootBadge.setAspectRatio(to: 1.0)
        self.inFootBadge.font = UIFont.systemFont(ofSize: 12.0)
        self.inFootBadge.textAlignment = .center
        self.inFootBadge.adjustsFontSizeToFitWidth = true
        
        self.hasNaturalBadge = UILabel()
        self.addSubview(self.hasNaturalBadge)
        self.hasNaturalBadge.centerHorizontally(in: self)
        self.hasNaturalBadge.pin(edge: .bottom, to: .bottom, of: self, with: 5.0)
        self.hasNaturalBadge.pinWidth(toWidthOf: self, multiplier: 0.3, constant: 0.0)
        self.hasNaturalBadge.setAspectRatio(to: 1.0)
        self.hasNaturalBadge.font = UIFont.systemFont(ofSize: 12.0)
        self.hasNaturalBadge.textAlignment = .center
        self.hasNaturalBadge.adjustsFontSizeToFitWidth = true

        self.hasUnnaturalBadge = UILabel()
        self.addSubview(self.hasUnnaturalBadge)
        self.hasUnnaturalBadge.pin(edge: .trailing, to: .trailing, of: self)
        self.hasUnnaturalBadge.pin(edge: .bottom, to: .bottom, of: self, with: 5.0)
        self.hasUnnaturalBadge.pinWidth(toWidthOf: self, multiplier: 0.3, constant: 0.0)
        self.hasUnnaturalBadge.setAspectRatio(to: 1.0)
        self.hasUnnaturalBadge.font = UIFont.systemFont(ofSize: 12.0)
        self.hasUnnaturalBadge.textAlignment = .center
        self.hasUnnaturalBadge.adjustsFontSizeToFitWidth = true
        
        self.tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(OpponentPreviewView.tapGestureRecognizerChanged))
        self.addGestureRecognizer(self.tapGestureRecognizer)
    }
    
    func update(user: User, player: Player, game: Game) {
        self.nameLabel.text = user.firstName!
        
        if player.isInFoot {
            self.inFootBadge.text = "🦶"
        } else {
            self.inFootBadge.text = "✋"
        }
        
        if player.hasNaturalBook(in: game.round!) {
            self.hasNaturalBadge.text = "🟥"
        } else {
            self.hasNaturalBadge.text = "⬜️"
        }

        if player.hasUnnaturalBook(in: game.round!) {
            self.hasUnnaturalBadge.text = "⬛️"
        } else {
            self.hasUnnaturalBadge.text = "⬜️"
        }
        
        self.player = player
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        self.circleView.layer.cornerRadius = self.frame.width / 2.0
    }
    
    @objc func tapGestureRecognizerChanged(_ sender: Any) {
        if self.tapGestureRecognizer.state == .ended {
            self.delegate?.opponentPreviewViewTapped(player: self.player!)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

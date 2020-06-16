//
//  FootView.swift
//  HandAndFoot
//
//  Created by Ben Oztalay on 5/25/20.
//  Copyright © 2020 Ben Oztalay. All rights reserved.
//

import UIKit

class FootView: UIView {

    private var footLabel: UILabel!
    
    init() {
        super.init(frame: .zero)
        
        self.backgroundColor = .white
        self.layer.cornerCurve = .continuous
        self.layer.cornerRadius = 10;
        self.layer.masksToBounds = true
        self.layer.borderWidth = 1
        self.layer.borderColor = UIColor.black.cgColor
        
        self.footLabel = UILabel()
        self.addSubview(self.footLabel)
        self.footLabel.centerHorizontally(in: self)
        self.footLabel.centerVertically(in: self)
        self.footLabel.pinX(to: self)
        self.footLabel.font = UIFont.systemFont(ofSize: 24.0)
        self.footLabel.textAlignment = .center
        
        self.update(footPresent: false)
    }
    
    func update(footPresent: Bool) {
        if footPresent {
            self.footLabel.text = "🦶"
        } else {
            self.footLabel.text = "❌"
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

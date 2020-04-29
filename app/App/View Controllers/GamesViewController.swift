//
//  GamesViewController.swift
//  HandAndFoot
//
//  Created by Ben Oztalay on 4/28/20.
//  Copyright © 2020 Ben Oztalay. All rights reserved.
//

import UIKit

class GamesViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    var gameListTableView: UITableView
    var gamePreviewView: GamePreviewView

    init() {
        self.gameListTableView = UITableView()
        self.gamePreviewView = GamePreviewView()
        
        super.init(nibName: nil, bundle: nil)

        self.gameListTableView.delegate = self
        self.gameListTableView.dataSource = self
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = .white
        
        self.view.addSubview(self.gameListTableView)
        self.gameListTableView.pin(edge: .leading, to: .leading, of: self.view)
        self.gameListTableView.pin(edge: .top, to: .top, of: self.view)
        self.gameListTableView.pin(edge: .bottom, to: .bottom, of: self.view)
        self.gameListTableView.pinWidth(toWidthOf: self.view, multiplier: 0.3)
        
        self.view.addSubview(self.gamePreviewView)
        self.gamePreviewView.pin(edge: .leading, to: .trailing, of: self.gameListTableView)
        self.gamePreviewView.pin(edge: .top, to: .top, of: self.view)
        self.gamePreviewView.pin(edge: .bottom, to: .bottom, of: self.view)
        self.gamePreviewView.pin(edge: .trailing, to: .trailing, of: self.view)
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return UITableViewCell()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

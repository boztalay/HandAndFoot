//
//  NewGameViewController.swift
//  HandAndFoot
//
//  Created by Ben Oztalay on 5/18/20.
//  Copyright © 2020 Ben Oztalay. All rights reserved.
//

import UIKit

class NewGameViewController: UIViewController {

    init() {
        super.init(nibName: nil, bundle: nil)
        
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Cancel", style: .plain, target: self, action: #selector(NewGameViewController.cancelButtonPressed))
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(NewGameViewController.doneButtonPressed))
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = .white
        
        self.title = "New Game"
    }
    
    @objc func cancelButtonPressed(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    @objc func doneButtonPressed(_ sender: Any) {
        
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

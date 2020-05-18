//
//  ProfileViewController.swift
//  HandAndFoot
//
//  Created by Ben Oztalay on 5/18/20.
//  Copyright © 2020 Ben Oztalay. All rights reserved.
//

import UIKit

class ProfileViewController: UIViewController {

    init() {
        super.init(nibName: nil, bundle: nil)
        
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Cancel", style: .plain, target: self, action: #selector(ProfileViewController.cancelButtonPressed))
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Edit", style: .done, target: self, action: #selector(ProfileViewController.editButtonPressed))
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = .white
        
        self.title = "Profile"
    }
    
    @objc func cancelButtonPressed(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    @objc func editButtonPressed(_ sender: Any) {
        
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

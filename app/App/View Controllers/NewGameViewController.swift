//
//  NewGameViewController.swift
//  HandAndFoot
//
//  Created by Ben Oztalay on 5/18/20.
//  Copyright © 2020 Ben Oztalay. All rights reserved.
//

import UIKit

class NewGameViewController: UIViewController, UserSearchViewControllerDelegate {

    var titleTextField: UITextField!
    
    init() {
        super.init(nibName: nil, bundle: nil)

        self.titleTextField = UITextField()
        self.titleTextField.borderStyle = .roundedRect
        self.titleTextField.textContentType = .name
        self.titleTextField.placeholder = "Game Title"
        
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Cancel", style: .plain, target: self, action: #selector(NewGameViewController.cancelButtonPressed))
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Next", style: .plain, target: self, action: #selector(NewGameViewController.nextButtonPressed))
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = .white
        
        self.title = "New Game"
        
        self.view.addSubview(self.titleTextField)
        self.titleTextField.pinX(to: self.view.safeAreaLayoutGuide, leading: 40, trailing: -40)
        self.titleTextField.pin(edge: .top, to: .top, of: self.view.safeAreaLayoutGuide, with: 40)
    }
    
    @objc func cancelButtonPressed(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    @objc func nextButtonPressed(_ sender: Any) {
        // TODO: Check that there's a game title
        
        let userSearchViewController = UserSearchViewController()
        userSearchViewController.delegate = self
        self.navigationController?.pushViewController(userSearchViewController, animated: true)
    }
    
    func userSearchComplete(users: [User]) {

    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

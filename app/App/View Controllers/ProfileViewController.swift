//
//  ProfileViewController.swift
//  HandAndFoot
//
//  Created by Ben Oztalay on 5/18/20.
//  Copyright © 2020 Ben Oztalay. All rights reserved.
//

import UIKit

class ProfileViewController: GroupSectionViewController {
    
    weak var logOutDelegate: LogOutDelegate?

    init() {
        super.init()
        
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Cancel", style: .plain, target: self, action: #selector(ProfileViewController.cancelButtonPressed))
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Edit", style: .done, target: self, action: #selector(ProfileViewController.editButtonPressed))
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Profile"
    }
    
    override func sections() -> [Section] {
        guard let user = DataManager.shared.currentUser else {
            fatalError("No current user")
        }
        
        return [
            Section(
                title: "Profile",
                rows: [
                    Row(name: "Email", detail: "\(user.email!)"),
                    Row(name: "Name", detail: "\(user.firstName!) \(user.lastName!)"),
                    Row(name: "Joined", detail: "\(DateFormatter.friendlyDateString(from: user.created!))")
                ]
            ),
            Section(
                title: "Account",
                rows:[
                    Row(name: "Log Out", detail: nil, action: #selector(ProfileViewController.logOutButtonPressed), destructive: true)
                ]
            )
        ]
    }
    
    @objc func cancelButtonPressed(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    @objc func editButtonPressed(_ sender: Any) {
        
    }
    
    @objc func logOutButtonPressed() {
        Network.shared.sendLogoutRequest() { (success, httpStatusCode, response) in
            guard success else {
                UIAlertController.presentErrorAlert(on: self, title: "Couldn't Log Out")
                return
            }
            
            DataManager.shared.clearLocalData()
            self.dismiss(animated: true) {
                self.logOutDelegate?.userLoggedOut()
            }
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

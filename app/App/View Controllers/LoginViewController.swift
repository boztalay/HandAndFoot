//
//  LoginViewController.swift
//  HandAndFoot
//
//  Created by Ben Oztalay on 4/14/20.
//  Copyright © 2020 Ben Oztalay. All rights reserved.
//

import UIKit

enum LoginViewControllerMode: String, CaseIterable {
    case logIn = "Log In"
    case signUp = "Sign Up"
}

class LoginViewController: UIViewController, LogOutDelegate {
    
    var modeSegmentedControl: UISegmentedControl!
    var nameTextField: UITextField!
    var emailTextField: UITextField!
    var passwordTextField: UITextField!
    var passwordConfirmationTextField: UITextField!
    var logInButton: UIButton!
    var signUpButton: UIButton!
    
    var mode: LoginViewControllerMode!
    
    init() {
        super.init(nibName: nil, bundle: nil)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = .white
        
        self.setUpViews()
        self.setMode(.logIn)
        
        if let currentUser = DataManager.shared.currentUser {
            self.handleLogin(with: currentUser.email!, true)
        }
    }
    
    func setUpViews() {
        self.modeSegmentedControl = UISegmentedControl(items: LoginViewControllerMode.allCases.map({ $0.rawValue }))
        self.view.addSubview(self.modeSegmentedControl)
        self.modeSegmentedControl.centerHorizontally(in: self.view)
        self.modeSegmentedControl.pin(edge: .top, to: .top, of: self.view, with: 250.0)
        self.modeSegmentedControl.addTarget(self, action: #selector(LoginViewController.modeSegmentedControlChanged), for: .valueChanged)
        self.modeSegmentedControl.selectedSegmentIndex = 0
        
        self.emailTextField = UITextField()
        self.emailTextField.borderStyle = .roundedRect
        self.emailTextField.textAlignment = .center
        self.emailTextField.textContentType = .emailAddress
        self.emailTextField.autocapitalizationType = .none
        self.emailTextField.placeholder = "Electronic Mail Address"
        
        self.passwordTextField = UITextField()
        self.passwordTextField.borderStyle = .roundedRect
        self.passwordTextField.textAlignment = .center
        self.passwordTextField.textContentType = .password
        self.passwordTextField.placeholder = "Password"
        self.passwordTextField.isSecureTextEntry = true
        
        self.nameTextField = UITextField()
        self.nameTextField.borderStyle = .roundedRect
        self.nameTextField.textAlignment = .center
        self.nameTextField.textContentType = .name
        self.nameTextField.placeholder = "Name"
        
        self.passwordConfirmationTextField = UITextField()
        self.passwordConfirmationTextField.borderStyle = .roundedRect
        self.passwordConfirmationTextField.textAlignment = .center
        self.passwordConfirmationTextField.textContentType = .password
        self.passwordConfirmationTextField.placeholder = "Password (Again [Sorry])"
        self.passwordConfirmationTextField.isSecureTextEntry = true
        
        self.logInButton = UIButton(type: .system)
        self.logInButton.setTitle(LoginViewControllerMode.logIn.rawValue, for: .normal)
        self.logInButton.addTarget(self, action: #selector(LoginViewController.logInOrSignUpButtonPressed), for: .touchUpInside)
        
        self.signUpButton = UIButton(type: .system)
        self.signUpButton.setTitle(LoginViewControllerMode.signUp.rawValue, for: .normal)
        self.signUpButton.addTarget(self, action: #selector(LoginViewController.logInOrSignUpButtonPressed), for: .touchUpInside)
    }

    @objc func modeSegmentedControlChanged(_ sender: Any) {
        let mode = LoginViewControllerMode.allCases[self.modeSegmentedControl.selectedSegmentIndex]
        self.setMode(mode)
    }
    
    func setMode(_ mode: LoginViewControllerMode) {
        self.mode = mode
        
        self.nameTextField.removeFromSuperview()
        self.emailTextField.removeFromSuperview()
        self.passwordTextField.removeFromSuperview()
        self.passwordConfirmationTextField.removeFromSuperview()
        self.logInButton.removeFromSuperview()
        self.signUpButton.removeFromSuperview()
        
        switch self.mode! {
            case .logIn:
                self.setUpViewsForLoggingIn()
            case .signUp:
                self.setUpViewsForSigningUp()
        }
        
        self.nameTextField.setWidth(to: 300.0)
        self.emailTextField.setWidth(to: 300.0)
        self.passwordTextField.setWidth(to: 300.0)
        self.passwordConfirmationTextField.setWidth(to: 300.0)
        self.logInButton.setWidth(to: 300.0)
        self.signUpButton.setWidth(to: 300.0)
    }
    
    func setUpViewsForLoggingIn() {
        self.view.addSubview(self.emailTextField)
        self.emailTextField.centerHorizontally(in: self.view)
        self.emailTextField.pin(edge: .top, to: .bottom, of: self.modeSegmentedControl, with: 25.0)
        
        self.view.addSubview(self.passwordTextField)
        self.passwordTextField.centerHorizontally(in: self.view)
        self.passwordTextField.pin(edge: .top, to: .bottom, of: self.emailTextField, with: 10.0)
        
        self.view.addSubview(self.logInButton)
        self.logInButton.setTitle(self.mode.rawValue, for: .normal)
        self.logInButton.centerHorizontally(in: self.view)
        self.logInButton.pin(edge: .top, to: .bottom, of: self.passwordTextField, with: 25.0)
    }
    
    func setUpViewsForSigningUp() {
        self.view.addSubview(self.nameTextField)
        self.nameTextField.centerHorizontally(in: self.view)
        self.nameTextField.pin(edge: .top, to: .bottom, of: self.modeSegmentedControl, with: 25.0)
        
        self.view.addSubview(self.emailTextField)
        self.emailTextField.centerHorizontally(in: self.view)
        self.emailTextField.pin(edge: .top, to: .bottom, of: self.nameTextField, with: 10.0)
        
        self.view.addSubview(self.passwordTextField)
        self.passwordTextField.centerHorizontally(in: self.view)
        self.passwordTextField.pin(edge: .top, to: .bottom, of: self.emailTextField, with: 10.0)

        self.view.addSubview(self.passwordConfirmationTextField)
        self.passwordConfirmationTextField.centerHorizontally(in: self.view)
        self.passwordConfirmationTextField.pin(edge: .top, to: .bottom, of: self.passwordTextField, with: 10.0)
        
        self.view.addSubview(self.signUpButton)
        self.signUpButton.setTitle(self.mode.rawValue, for: .normal)
        self.signUpButton.centerHorizontally(in: self.view)
        self.signUpButton.pin(edge: .top, to: .bottom, of: self.passwordConfirmationTextField, with: 25.0)
    }
    
    @objc func logInOrSignUpButtonPressed(_ sender: Any) {
        guard let name = self.nameTextField.text,
              let email = self.emailTextField.text,
              let password = self.passwordTextField.text,
              let passwordConfirmation = self.passwordConfirmationTextField.text else {
            fatalError("Whaaaaaat")
        }
        
        if self.mode == .logIn {
            Network.shared.sendLoginRequest(email: email, password: password) { (success, httpStatusCode, response) in
                self.handleLogin(with: email, success)
            }
        } else if self.mode == .signUp {
            guard password == passwordConfirmation else {
                UIAlertController.presentErrorAlert(on: self, title: "Password Mismatch", message: "Passwords don't match!")
                return
            }
            
            Network.shared.sendSignUpRequest(name: name, email: email, password: password) { (success, httpStatusCode, response) in
                self.handleLogin(with: email, success)
            }
        }
    }
    
    func handleLogin(with email: String, _ success: Bool) {
        guard success else {
            UIAlertController.presentErrorAlert(on: self, title: "Login Failure", message: "Couldn't log in!")
            return
        }

        DataManager.shared.setCurrentUser(with: email)
        DataManager.shared.sync() { (success) in
            guard success else {
                UIAlertController.presentErrorAlert(on: self, title: "Sync Failure", message: "Couldn't sync!")
                return
            }
            
            Network.shared.subscribeToPusherChannel(for: DataManager.shared.currentUser!)
            
            let gamesViewController = GamesViewController()
            gamesViewController.logOutDelegate = self
            let navigationController = UINavigationController(rootViewController: gamesViewController)
            navigationController.modalPresentationStyle = .fullScreen

            self.present(navigationController, animated: true, completion: nil)
        }
    }
    
    func userLoggedOut() {
        self.modeSegmentedControlChanged(self)
        self.nameTextField.text = nil
        self.emailTextField.text = nil
        self.passwordTextField.text = nil
        self.passwordConfirmationTextField.text = nil
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

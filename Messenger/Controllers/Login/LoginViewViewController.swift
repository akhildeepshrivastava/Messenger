//
//  LoginViewViewController.swift
//  Messenger
//
//  Created by Shweta Shrivastava on 12/28/20.
//

import UIKit
import FirebaseAuth
import FBSDKLoginKit
import GoogleSignIn

class LoginViewViewController: UIViewController {
    
    private let fbLoginButton: FBLoginButton = {
        let button = FBLoginButton()
        button.permissions = ["public_profile", "email"]
        return button
    }()
    
    private let googleLoginButton: GIDSignInButton = {
        let button = GIDSignInButton()
        return button
    }()
    
    
    private let scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.clipsToBounds = true
        return scrollView
    }()
    
    private let imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(named: "logo")
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    
    private let emailTextField: UITextField = {
        let field = UITextField()
        field.autocapitalizationType = .none
        field.autocorrectionType = .no
        field.returnKeyType = .continue
        field.layer.cornerRadius = 12
        field.keyboardType = .emailAddress
        field.layer.borderWidth = 1
        field.layer.borderColor = UIColor.lightGray.cgColor
        field.placeholder = "Email Address"
        field.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 5, height: 0))
        field.leftViewMode = .always
        field.backgroundColor = .white
        return field
    }()
    
    private let passwordField: UITextField = {
        let field = UITextField()
        field.autocapitalizationType = .none
        field.autocorrectionType = .no
        field.returnKeyType = .done
        field.layer.cornerRadius = 12
        field.layer.borderWidth = 1
        field.layer.borderColor = UIColor.lightGray.cgColor
        field.placeholder = "Password"
        field.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 5, height: 0))
        field.leftViewMode = .always
        field.backgroundColor = .white
        field.isSecureTextEntry = true
        return field
    }()
    
    
    private let loginButton: UIButton = {
        
        let button = UIButton()
        button.setTitle("Log In", for: .normal)
        button.backgroundColor = .link
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 12
        button.layer.masksToBounds = true
        button.titleLabel?.font = .systemFont(ofSize: 20, weight: .bold)
        return button
    }()
    
    private var loginObserver: NSObjectProtocol?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Log In"
        view.backgroundColor = .white
        // Do any additional setup after loading the view.
        GIDSignIn.sharedInstance()?.presentingViewController = self
        loginObserver = NotificationCenter.default.addObserver(forName: .didLoginNotification, object: nil, queue: .main) { [weak self] _ in
            self?.navigationController?.dismiss(animated: true, completion: nil)
        
        }
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Register", style: .done, target: self, action: #selector(didTapRegister))
        
        loginButton.addTarget(self, action: #selector(loginButtonTapped), for: .touchUpInside)
        
        emailTextField.delegate = self
        passwordField.delegate = self
        fbLoginButton.delegate = self
        
        view.addSubview(scrollView)
        scrollView.addSubview(imageView)
        scrollView.addSubview(emailTextField)
        scrollView.addSubview(passwordField)
        scrollView.addSubview(loginButton)
        scrollView.addSubview(googleLoginButton)
        
        loginButton.center = view.center
        scrollView.addSubview(fbLoginButton)
        
    }
    
    deinit {
        if let observer = loginObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        scrollView.frame = view.bounds
        
        let size = scrollView.width/3
        imageView.frame = CGRect(x: (scrollView.width-size)/2, y: 20, width: size, height: size)
        
        emailTextField.frame = CGRect(x: 30,
                                      y: imageView.bottom+10,
                                      width: scrollView.width-60,
                                      height: 52)
        
        passwordField.frame = CGRect(x: 30,
                                     y: emailTextField.bottom+10,
                                     width: scrollView.width-60,
                                     height: 52)
        
        loginButton.frame = CGRect(x: 30,
                                   y: passwordField.bottom+10,
                                   width: scrollView.width-60,
                                   height: 52)
        
        fbLoginButton.frame = CGRect(x: 30,
                                     y: loginButton.bottom+10,
                                     width: scrollView.width-60,
                                     height: 52)
        
        googleLoginButton.frame = CGRect(x: 30,
                                     y: fbLoginButton.bottom+10,
                                     width: scrollView.width-60,
                                     height: 52)
    }
    
    @objc private func loginButtonTapped() {
        emailTextField.resignFirstResponder()
        passwordField.resignFirstResponder()
        guard let email = emailTextField.text, let password = passwordField.text, !email.isEmpty, !password.isEmpty, password.count >= 6 else {
            alertUserLoginError( )
            return
        }
        
        //FireBase LogIn
        FirebaseAuth.Auth.auth().signIn(withEmail: email, password: password) { [weak self ] (authResult, error) in
            
            guard let strongSelf = self else {
                return
            }
            
            guard let result = authResult, error == nil else {
                print("Error while log in")
                return
            }
            let user = result.user
            print("User logged in \(user)")
            strongSelf.navigationController?.dismiss(animated: true, completion: nil)
        }
        
    }
    
    private func alertUserLoginError() {
        let alert = UIAlertController(title: "Woops", message: "Please enter all information to log in", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Dismiss", style: .cancel, handler: nil))
        present(alert, animated: true)
        
        
    }
    
    @objc private func didTapRegister() {
        let registerVC = RegisterViewController()
        registerVC.title = "Create Account"
        navigationController?.pushViewController(registerVC, animated: true)
    }
    
}

extension LoginViewViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == emailTextField {
            passwordField.becomeFirstResponder()
        } else if textField == passwordField {
            self.loginButtonTapped()
        }
        
        return true
    }
}

extension LoginViewViewController: LoginButtonDelegate {
    
    func loginButtonDidLogOut(_ loginButton: FBLoginButton) {
        //no operation
    }
    
    func loginButton(_ loginButton: FBLoginButton, didCompleteWith result: LoginManagerLoginResult?, error: Error?) {
        guard let token = result?.token?.tokenString else {
            print("User failed to login with facebook")
            return
        }
        let fbRequest = FBSDKLoginKit.GraphRequest(graphPath: "me", parameters: ["fields" : "email, name"], tokenString: token, version: nil, httpMethod: .get)
        fbRequest.start { (_, result, error) in
            
            guard let result = result as? [String: Any], error == nil else {
                print("Failed to make facebook grap[h request")
                return
            }
            
            print(result)
            guard let userName = result["name"] as? String, let email = result["email"] as? String else {
                return
            }
            
            let nameComponeents = userName.components(separatedBy: " ")
            guard nameComponeents.count == 2 else {
                return
            }
            
            let firstname = nameComponeents[0]
            let lastname = nameComponeents[1]
            
            DataBaseManager.shared.userExists(with: email) { (exist) in
                if !exist {
                    DataBaseManager.shared.inserUser(with: ChatAppUser(firstName: firstname, lastName: lastname, emailAddress: email))
                }
            }
            
            let credentilas = FacebookAuthProvider.credential(withAccessToken: token)
            FirebaseAuth.Auth.auth().signIn(with: credentilas) { [weak self](authResult, error) in
                
                guard let strongSelf = self else {
                    return
                }
                
                guard authResult != nil, error == nil else {
                    print("Error while log in")
                    return
                }
                
                strongSelf.navigationController?.dismiss(animated: true, completion: nil)
                
            }
            
        }
    }
}

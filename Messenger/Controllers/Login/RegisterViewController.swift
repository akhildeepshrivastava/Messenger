//
//  RegisterViewController.swift
//  Messenger
//
//  Created by Shweta Shrivastava on 12/28/20.
//

import UIKit
import FirebaseAuth
import JGProgressHUD

class RegisterViewController: UIViewController {
    
    private let spinner = JGProgressHUD(style: .dark)

    private let scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.clipsToBounds = true
        return scrollView
    }()
    
    private let imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(systemName: "person.circle")
        imageView.tintColor = .gray
        imageView.contentMode = .scaleAspectFit
        imageView.layer.masksToBounds = true
        imageView.layer.borderWidth = 2
        imageView.layer.borderColor = UIColor.lightGray.cgColor
        return imageView
    }()
    
    private let emailTextField: UITextField = {
        let field = UITextField()
        field.autocapitalizationType = .none
        field.autocorrectionType = .no
        field.keyboardType = .emailAddress
        field.returnKeyType = .continue
        field.layer.cornerRadius = 12
        field.layer.borderWidth = 1
        field.layer.borderColor = UIColor.lightGray.cgColor
        field.placeholder = "Email Address"
        field.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 5, height: 0))
        field.leftViewMode = .always
//        field.backgroundColor = .white
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
//        field.backgroundColor = .white
        field.isSecureTextEntry = true
        return field
    }()
    
    private let firstNameField: UITextField = {
        let field = UITextField()
        field.autocapitalizationType = .none
        field.autocorrectionType = .no
        field.returnKeyType = .continue
        field.layer.cornerRadius = 12
        field.layer.borderWidth = 1
        field.layer.borderColor = UIColor.lightGray.cgColor
        field.placeholder = "First Name"
        field.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 5, height: 0))
        field.leftViewMode = .always
//        field.backgroundColor = .white
        return field
    }()
    
    private let lastNameField: UITextField = {
        let field = UITextField()
        field.autocapitalizationType = .none
        field.autocorrectionType = .no
        field.returnKeyType = .continue
        field.layer.cornerRadius = 12
        field.layer.borderWidth = 1
        field.layer.borderColor = UIColor.lightGray.cgColor
        field.placeholder = "Last Name"
        field.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 5, height: 0))
        field.leftViewMode = .always
//        field.backgroundColor = .white
        return field
    }()
    
    private let registerButton: UIButton = {
        
        let button = UIButton()
        button.setTitle("Register", for: .normal)
        button.backgroundColor = .systemGreen
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 12
        button.layer.masksToBounds = true
        button.titleLabel?.font = .systemFont(ofSize: 20, weight: .bold)
        return button
    }()
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Rigister", style: .done, target: self, action: #selector(didTapRegister))
        
        registerButton.addTarget(self, action: #selector(registerButtonTapped), for: .touchUpInside)
        emailTextField.delegate = self
        passwordField.delegate = self
        
        view.addSubview(scrollView)
        scrollView.addSubview(imageView)
        scrollView.addSubview(emailTextField)
        scrollView.addSubview(passwordField)
        scrollView.addSubview(registerButton)
        scrollView.addSubview(firstNameField)
        scrollView.addSubview(lastNameField)
        
        imageView.isUserInteractionEnabled = true
        scrollView.isUserInteractionEnabled = true
        
        let gesture = UITapGestureRecognizer(target: self, action: #selector(didTapChangeprofilePic))
        imageView.addGestureRecognizer(gesture)
        
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        scrollView.frame = view.bounds
        
        let size = scrollView.width/3
        
        imageView.frame = CGRect(x: (scrollView.width-size)/2, y: 20, width: size, height: size)
        imageView.layer.cornerRadius = imageView.width / 2.0

        
        firstNameField.frame = CGRect(x: 30,
                                      y: imageView.bottom+10,
                                      width: scrollView.width-60,
                                      height: 52)
        
        
        lastNameField.frame = CGRect(x: 30,
                                      y: firstNameField.bottom+10,
                                      width: scrollView.width-60,
                                      height: 52)
        
        
        emailTextField.frame = CGRect(x: 30,
                                      y: lastNameField.bottom+10,
                                      width: scrollView.width-60,
                                      height: 52)
        
        passwordField.frame = CGRect(x: 30,
                                     y: emailTextField.bottom+10,
                                     width: scrollView.width-60,
                                     height: 52)
        
        registerButton.frame = CGRect(x: 30,
                                   y: passwordField.bottom+10,
                                   width: scrollView.width-60,
                                   height: 52)
        
    }
    
    @objc private func registerButtonTapped() {
        emailTextField.resignFirstResponder()
        passwordField.resignFirstResponder()
        firstNameField.resignFirstResponder()
        lastNameField.resignFirstResponder()
        guard let email = emailTextField.text,
              let password = passwordField.text,
              let firstName = firstNameField.text,
              let lastName = lastNameField.text,
              !email.isEmpty,
              !password.isEmpty,
              !firstName.isEmpty,
              !lastName.isEmpty,
              password.count >= 6 else {
            alertUserLoginError( )
            return
        }
        
        spinner.show(in: view)
        
        DataBaseManager.shared.userExists(with: email) { [weak self] (exist) in
            guard let strongSelf = self else {
                return
            }
            guard !exist else {
                //User already exists
                strongSelf.alertUserLoginError(messageParam: "User Already Exists")
                return
            }
            
            DispatchQueue.main.async {
                strongSelf.spinner.dismiss()

            }
            
            //FireBase Registration
            FirebaseAuth.Auth.auth().createUser(withEmail: email, password: password) { (authResult, error) in
                
                guard authResult != nil , error == nil else {
                    print("Error creatin user")
                    return
                }
                let chatUser = ChatAppUser(firstName: firstName, lastName: lastName, emailAddress: email)

                DataBaseManager.shared.inserUser(with: chatUser) { (success) in
                    if success {
                        guard let image = strongSelf.imageView.image, let data = image.pngData() else {
                            return
                        }
                        let fileName = chatUser.profilePictrueFileName
                        StorageManager.shared.uploadProfilePic(with: data, fileName: fileName) { (result) in
                            switch result {
                            case .success(let dowloadUrl):
                                print(dowloadUrl)
                                UserDefaults.standard.set(dowloadUrl, forKey: "profile_picture_url")
                            case .failure(let error):
                                print("StorageError \(error)")
                            }
                        }
                        
                    }
                }
                strongSelf.navigationController?.dismiss(animated: true, completion: nil)

            }
        }
    }
    
    private func alertUserLoginError(messageParam: String = "Please enter all information to create a new account") {
        let alert = UIAlertController(title: "Woops", message: messageParam, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Dismiss", style: .cancel, handler: nil))
        present(alert, animated: true)
        
        
    }
    
    @objc private func didTapChangeprofilePic() {
        presentPhotoActionSheet()
    }
    
    @objc private func didTapRegister() {
        let registerVC = RegisterViewController()
        registerVC.title = "Create Account"
        navigationController?.pushViewController(registerVC, animated: true)
    }
    
}

extension RegisterViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == emailTextField {
            passwordField.becomeFirstResponder()
        } else if textField == passwordField {
            self.registerButtonTapped()
        }
        
        return true
    }
}

extension RegisterViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true, completion: nil)
        guard let selectedImage = info[UIImagePickerController.InfoKey.editedImage] as? UIImage else {
            return
        }
        self.imageView.image = selectedImage
    }
    
    func presentPhotoActionSheet() {
        let actionSheet = UIAlertController(title: "Profile Picture",
                                            message: "How wopuld you like to select a picture",
                                            preferredStyle: .actionSheet)
        
        actionSheet.addAction(UIAlertAction(title: "Cancel",
                                            style: .cancel,
                                            handler: nil))
        actionSheet.addAction(UIAlertAction(title: "Take Photo",
                                            style: .default,
                                            handler: { [weak self] _ in
                                                self?.presentCamera()
        }))
        
        actionSheet.addAction(UIAlertAction(title: "Choose Photo",
                                            style: .default,
                                            handler: { [weak self] _ in
                                                self?.presentPhotoPicker()
        }))
        
        present(actionSheet, animated: true)

    }
    
    func presentCamera() {
        let vc = UIImagePickerController()
        vc.sourceType = .camera
        vc.delegate = self
        vc.allowsEditing = true
        present(vc, animated: true)
    }
    
    func presentPhotoPicker() {
        let vc = UIImagePickerController()
        vc.sourceType = .photoLibrary
        vc.delegate = self
        vc.allowsEditing = true
        present(vc, animated: true)
    }
}

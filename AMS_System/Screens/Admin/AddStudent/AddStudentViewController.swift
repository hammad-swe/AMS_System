//
//  AddStudentViewController.swift
//  AMS_System
//
//  Created by Hammad Ali on 06/05/2026.
//

import UIKit
import FirebaseAuth

class AddStudentViewController: UIViewController {

    @IBOutlet weak var nameField: UITextField!
    @IBOutlet weak var emailField: UITextField!
    @IBOutlet weak var passwordField: UITextField!
    @IBOutlet weak var  saveButton: UIButton!
    
    @IBOutlet weak var errorLabel: UILabel!
    
    
    var adminUID: String?
        var onStudentAdded: (() -> Void)?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Add Student"
        errorLabel.isHidden = true
        // Do any additional setup after loading the view.
    }

    @IBAction func saveTapped(_ sender: UIButton) {
//        print("🔘 saveTapped fired")
//            print("   nameField.text = '\(nameField.text ?? "NIL")'")
//            print("   emailField.text = '\(emailField.text ?? "NIL")'")
//            print("   passwordField.text = '\(passwordField.text ?? "NIL")'")
//            print("   adminUID = '\(adminUID ?? "NIL")'")

        
        
        
        
            guard let name     =  nameField.text,     !name.isEmpty,
                  let email    = emailField.text,    !email.isEmpty,
                  let password =  passwordField.text, !password.isEmpty else {
                showError("All fields are required.")
                return
            }

//            guard let adminUID = adminUID else {
//                print("🔴 adminUID is nil")
//                return }
        
        // Get adminUID directly from current signed-in user
            guard let adminUID = Auth.auth().currentUser?.uid else {
                showError("Session expired. Please sign in again.")
                return
            }

            print("✅ adminUID: \(adminUID)")


        saveButton.isEnabled = false

            StudentManager.shared.addStudent(name:     name,
                                             email:    email,
                                             password: password,
                                             adminUID: adminUID) { [weak self] result in
                DispatchQueue.main.async {
                    self?.saveButton.isEnabled = true
                    switch result {
                    case .success:
                        self?.onStudentAdded?()
                        self?.navigationController?.popViewController(animated: true)
                    case .failure(let error):
                        self?.showError(error.localizedDescription)
                    }
                }
            }
        }

        private func showError(_ message: String) {
            errorLabel.text    = message
            errorLabel.isHidden = false
        }
    }



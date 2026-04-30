//
//  LoginViewController.swift
//  AMS_System
//
//  Created by Hammad Ali on 27/04/2026.
//

import UIKit
import GoogleSignIn
import FirebaseAuth

class LoginViewController: UIViewController {
    
    
   
    @IBOutlet weak var nameField: UITextField!
    
    @IBOutlet weak var passWordField: UITextField!
    
    @IBOutlet weak var googleSignInButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.hidesBackButton = true
        
        let backButton = UIBarButtonItem(
                image: UIImage(systemName: "chevron.backward"),
                style: .plain,
                target: self,
                action: #selector(backPressed)
            )
            navigationItem.leftBarButtonItem = backButton
        
    }
    
    @objc func backPressed(){
        self.navigationController?.popViewController(animated: true)
    }

    @IBAction func forgetTapped(_ sender: Any) {
    }
    
    @IBAction func loginTapped(_ sender: Any) {
        guard let email = nameField.text, !email.isEmpty,
                    let password = passWordField.text, !password.isEmpty else {
                  showAlert("Please enter email & password")
                  return
              }
//        Auth.auth().signIn(withEmail: email, password: password) { authResult, error in
//                    if let error = error {
//                        self.showAlert(error.localizedDescription)
//                        return
//                    }
//
//                    self.goToDashboard()
//                }
        
        
        
    }
    
    
    @IBAction func appleTapped(_ sender: Any) {
        
    }
    

    @IBAction func googleTapped(_ sender: Any) {
        setLoading(true)
               // errorLabel.isHidden = true

                AuthManager.shared.signInWithGoogle(presenting: self) { [weak self] result in
                    DispatchQueue.main.async {
                        self?.setLoading(false)
                        switch result {
                        case .success(let (user, role)):
                            self?.navigate(user: user, role: role)
                        case .failure(let error):
                            self?.showError(error.localizedDescription)
                        }
                    }
                }
    }
    
    
    // MARK: - Restore Previous Session
    private func checkPreviousSignIn() {
           setLoading(true)
           AuthManager.shared.restorePreviousSignIn { [weak self] result in
               DispatchQueue.main.async {
                   self?.setLoading(false)
                   if case .success(let (user, role)) = result {
                       self?.navigate(user: user, role: role)
                   }
               }
           }
       }
    // MARK: - Role-based Navigation
        private func navigate(user: FirebaseAuth.User, role: UserRole) {
            let vc: UIViewController

            switch role {
            case .admin:
                let adminVC = AdminDashboardViewController(nibName: "AdminDashboardViewController", bundle: nil)
                adminVC.user = user
                vc = adminVC

            case .student:
                let studentVC = StudentDashboardViewController(nibName: "StudentDashboardViewController", bundle: nil)
                studentVC.user = user
                vc = studentVC
            }

            navigationController?.setViewControllers([vc], animated: true)
        }

    
    @IBAction func signuptapped(_ sender: Any) {
        goToSignUp()
        
    }
    
    // navigate to signup
    func goToSignUp(){
        let vc = SignupViewController()
        self.navigationController?.setViewControllers([vc], animated: true)
    }
    // alert
    func showAlert(_ msg: String) {
            let alert = UIAlertController(title: "Info", message: msg, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
        }
    
    // MARK: - Helpers
        private func setLoading(_ loading: Bool) {
            googleSignInButton.isEnabled = !loading
            googleSignInButton.alpha = loading ? 0.6 : 1.0
            //loading ? activityIndicator.startAnimating() : activityIndicator.stopAnimating()
        }

        private func showError(_ message: String) {
//            errorLabel.text = message
//            errorLabel.isHidden = false
        }

}

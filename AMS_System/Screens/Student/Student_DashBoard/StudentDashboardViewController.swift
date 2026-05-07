//
//  StudentDashboardViewController.swift
//  AMS_System
//
//  Created by Hammad Ali on 29/04/2026.
//

//import UIKit
//
//class StudentDashboardViewController: UIViewController {
//
//    override func viewDidLoad() {
//        super.viewDidLoad()
//
//        // Do any additional setup after loading the view.
//    }
//
//}

import UIKit
import FirebaseAuth

class StudentDashboardViewController: UIViewController {
    
    
    var user: FirebaseAuth.User?
    private var todayRecord: AttendanceRecord?

    // MARK: - IBOutlets
    
    
    @IBOutlet weak var checkButton: UIButton!
    @IBOutlet weak var nameLabel: UILabel!


    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Stuent Dashboard"
        
        let signOutButton = UIBarButtonItem(
            title: "Sign Out",
            style: .plain,
            target: self,
            action: #selector(signOutTapped)
        )
        signOutButton.tintColor = .systemRed
        navigationItem.rightBarButtonItem = signOutButton
        
//        //checknutton design
//        
//        checkButton.layer.cornerRadius = checkButton.frame.width / 2
//
//            checkButton.layer.borderWidth = 8
//            checkButton.layer.borderColor = UIColor.white.cgColor
//
//            checkButton.clipsToBounds = true
        
//        setupUI()
//        populateUserInfo()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        checkButton.layer.cornerRadius = checkButton.frame.width / 2
        checkButton.layer.borderWidth = 8
                   checkButton.layer.borderColor = UIColor.blue.cgColor
        checkButton.clipsToBounds = true
    }
    
    // signout tapped
    @objc private func signOutTapped() {
        // Show confirmation alert first
        let alert = UIAlertController(
            title: "Sign Out",
            message: "Are you sure you want to sign out?",
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Sign Out", style: .destructive) { [weak self] _ in
            self?.performSignOut()
        })

        present(alert, animated: true)
    }

    private func performSignOut() {
        AuthManager.shared.signOut { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    // Navigate back to login screen
                    let loginVC = LoginViewController() // replace with your login VC
                    let nav = UINavigationController(rootViewController: loginVC)
                    nav.modalPresentationStyle = .fullScreen
                    self?.view.window?.rootViewController = nav
                    
                case .failure(let error):
                    let alert = UIAlertController(title: "Error", message: error.localizedDescription, preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "OK", style: .default))
                    self?.present(alert, animated: true)
                }
            }
        }
    }

}

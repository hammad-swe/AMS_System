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

    // MARK: - IBOutlets
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var emailLabel: UILabel!
    @IBOutlet weak var roleTagLabel: UILabel!
    @IBOutlet weak var signOutButton: UIButton!

    var user: FirebaseAuth.User?

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        populateUserInfo()
    }

    private func setupUI() {
        roleTagLabel.text = "STUDENT"
        roleTagLabel.backgroundColor = .systemBlue
        roleTagLabel.textColor = .white
        roleTagLabel.layer.cornerRadius = 6
        roleTagLabel.clipsToBounds = true
    }

    private func populateUserInfo() {
        nameLabel.text = user?.displayName ?? "Student"
        emailLabel.text = user?.email ?? ""
    }

    @IBAction func signOutTapped(_ sender: UIButton) {
        AuthManager.shared.signOut { [weak self] _ in
            DispatchQueue.main.async {
                let loginVC = LoginViewController(nibName: "LoginViewController", bundle: nil)
                self?.navigationController?.setViewControllers([loginVC], animated: true)
            }
        }
    }
}

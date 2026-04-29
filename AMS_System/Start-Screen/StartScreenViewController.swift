//
//  StartScreenViewController.swift
//  AMS_System
//
//  Created by Hammad Ali on 29/04/2026.
//

import UIKit

class StartScreenViewController: UIViewController {

    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.hidesBackButton = true
        // Do any additional setup after loading the view.
    }


    @IBAction func adminTapped(_ sender: Any) {
        let vc = AdminLoginViewController(nibName: "AdminLoginViewController", bundle: nil)
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    
    @IBAction func studentTapped(_ sender: Any) {
        let vc = LoginViewController(nibName: "LoginViewController", bundle: nil)
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
}

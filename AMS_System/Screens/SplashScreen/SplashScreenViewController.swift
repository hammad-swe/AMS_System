//
//  SplashScreenViewController.swift
//  AMS_System
//
//  Created by Hammad Ali on 27/04/2026.
//

import UIKit

class SplashScreenViewController: UIViewController {
    
    @IBOutlet weak var logoImage: UIImageView!
    @IBOutlet weak var Appname: UILabel!
    @IBOutlet weak var Subline: UILabel!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        splashStarter()
        
        // Do any additional setup after loading the view.
    }
    
    private func splashStarter(){
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0){ [weak self] in
            self?.goToLoginScreen()
        }
        
    }

    private func goToLoginScreen(){
        let vc = LoginViewController(nibName: "LoginViewController", bundle: nil)
        self.navigationController?.pushViewController(vc, animated: true)
    }

    

}

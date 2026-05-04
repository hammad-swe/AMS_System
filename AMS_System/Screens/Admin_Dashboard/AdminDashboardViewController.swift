//
//  AdminDashboardViewController.swift
//  AMS_System
//
//  Created by Hammad Ali on 29/04/2026.
//

//import UIKit
//
//class AdminDashboardViewController: UIViewController {
//
//    override func viewDidLoad() {
//        super.viewDidLoad()
//
//        // Do any additional setup after loading the view.
//    }
//
//
//}

import UIKit
import FirebaseAuth


class AdminDashboardViewController: UIViewController {
    
    @IBOutlet weak var AttendancePercentage: UILabel!
    
    var user: FirebaseAuth.User?

    
    override func viewDidLoad() {
        super.viewDidLoad()
  title = "Admin Dashboard"
        
    }
}

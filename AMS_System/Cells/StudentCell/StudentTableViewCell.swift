//
//  StudentTableViewCell.swift
//  AMS_System
//
//  Created by Hammad Ali on 06/05/2026.
//

import UIKit

class StudentTableViewCell: UITableViewCell {

    static let identifier = "StudentTableViewCell" 
    @IBOutlet weak var studentName: UILabel!
    @IBOutlet weak var statusButton: UIButton!
    
    
    var onToggle: ((AttendanceStatus) -> Void)?
        private var currentStatus: AttendanceStatus = .absent
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    // MARK: - Configure
      func configure(student: Student, status: AttendanceStatus) {
          studentName.text = student.name
          currentStatus  = status


          updateButtonUI()
      }
    
    private func updateButtonUI() {
         switch currentStatus {
         case .present:
             statusButton.setTitle("✅  Present", for: .normal)
             statusButton.backgroundColor = UIColor.systemGreen.withAlphaComponent(0.15)
             statusButton.setTitleColor(.systemGreen, for: .normal)

         case .absent:
             statusButton.setTitle("❌  Absent", for: .normal)
             statusButton.backgroundColor = UIColor.systemRed.withAlphaComponent(0.15)
             statusButton.setTitleColor(.systemRed, for: .normal)
         }
     }
    
}


//
//  StudentTableViewCell.swift
//  AMS_System
//
//  Created by Hammad Ali on 06/05/2026.
//

import UIKit

class StudentTableViewCell: UITableViewCell {

    
    @IBOutlet weak var avatarImageView: UIImageView!
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

          // Avatar initials
//          let initials = student.name
//              .split(separator: " ")
//              .prefix(2)
//              .compactMap { $0.first }
//              .map { String($0).uppercased() }
//              .joined()

//          avatarLabel.text          = initials.isEmpty ? "?" : initials
          //avatarImageView.backgroundColor = colorForName(student.name)

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


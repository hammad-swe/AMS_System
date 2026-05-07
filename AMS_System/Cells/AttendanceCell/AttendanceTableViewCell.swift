//
//  AttendanceTableViewCell.swift
//  AMS_System
//
//  Created by Hammad Ali on 06/05/2026.
//

import UIKit

class AttendanceTableViewCell: UITableViewCell {

    @IBOutlet weak var nameLabel: UILabel!


    @IBOutlet weak var emailLabel: UILabel!
    
    
    @IBOutlet weak var toggleButton: UIButton!
    
    
    private var currentStatus: AttendanceStatus = .absent
        var onToggle: ((AttendanceStatus) -> Void)?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    func configure(name: String, email: String, status: AttendanceStatus) {
            nameLabel.text  = name
            emailLabel.text = email
            currentStatus   = status
            updateButton()
        }
    
    private func updateButton() {
            switch currentStatus {
            case .present:
                toggleButton.setTitle("Present", for: .normal)
                toggleButton.backgroundColor = UIColor.systemGreen.withAlphaComponent(0.15)
                toggleButton.setTitleColor(.systemGreen, for: .normal)
            case .absent:
                toggleButton.setTitle("Absent", for: .normal)
                toggleButton.backgroundColor = UIColor.systemRed.withAlphaComponent(0.15)
                toggleButton.setTitleColor(.systemRed, for: .normal)
            }
        }

        @IBAction func toggleTapped(_ sender: UIButton) {
            currentStatus = currentStatus == .present ? .absent : .present
            updateButton()
            onToggle?(currentStatus)
        }
    }

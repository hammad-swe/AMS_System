//
//  AttendanceStatus.swift
//  AMS_System
//
//  Created by Hammad Ali on 04/05/2026.
//

import Foundation

enum AttendanceStatus: String, Codable {
    case present = "present"
    case absent  = "absent"
}

struct AttendanceRecord {
    let studentUID: String
    let studentName: String
    let date: String           // "2024-01-15"
    let status: AttendanceStatus
    let markedAt: Date

    var dictionary: [String: Any] {
        return [
            "studentUID":   studentUID,
            "studentName":  studentName,
            "date":         date,
            "status":       status.rawValue,
            "markedAt":     markedAt
        ]
    }
}


struct Student {
    let uid: String
    let name: String
    let email: String
    var attendanceStatus: AttendanceStatus? // used in UI only
}

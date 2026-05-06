//
//  AttendanceRecord.swift
//  AMS_System
//
//  Created by Hammad Ali on 06/05/2026.
//

import Foundation
import FirebaseFirestore

enum AttendanceStatus: String, Codable {
    case present = "present"
    case absent  = "absent"
}

struct AttendanceRecord {
    let studentUID: String
    let studentName: String
    let date: String
    var status: AttendanceStatus
    var checkIn: Date?
    var checkOut: Date?
    let markedAt: Date

    var dictionary: [String: Any] {
        var dict: [String: Any] = [
            "studentUID":  studentUID,
            "studentName": studentName,
            "date":        date,
            "status":      status.rawValue,
            "markedAt":    Timestamp(date: markedAt)
        ]
        if let checkIn  = checkIn  { dict["checkIn"]  = Timestamp(date: checkIn)  }
        if let checkOut = checkOut { dict["checkOut"] = Timestamp(date: checkOut) }
        return dict
    }

    // Attendance duration in minutes
    var durationMinutes: Int? {
        guard let i = checkIn, let o = checkOut else { return nil }
        return Int(o.timeIntervalSince(i) / 60)
    }
}

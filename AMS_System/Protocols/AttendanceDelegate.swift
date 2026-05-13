//
//  AttendanceDelegate.swift
//  AMS_System
//
//  Created by Hammad Ali on 13/05/2026.
//

import Foundation
protocol AttendanceDelegate: AnyObject {
    func didSaveAttendance(_ attendanceMap: [String: AttendanceStatus], date: String)
}

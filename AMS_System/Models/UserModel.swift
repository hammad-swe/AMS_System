//
//  UserModel.swift
//  AMS_System
//
//  Created by Hammad Ali on 29/04/2026.
//

import Foundation
import FirebaseFirestore

enum UserRole: String, Codable {
    case admin   = "admin"
    case student = "student"
}

struct AppUser: Codable {
    let uid: String
    let name: String
    let email: String
    let role: UserRole
    let createdAt: Date

    // Firestore collection based on role
    var collection: String {
        switch role {
        case .admin:   return "admin"
        case .student: return "students"
        }
    }
}

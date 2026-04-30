//
//  AuthManager.swift
//  AMS_System
//
//  Created by Hammad Ali on 30/04/2026.
//
import Foundation
import FirebaseAuth
import FirebaseCore
import GoogleSignIn

final class AuthManager {

    static let shared = AuthManager()
    private init() {}

    var currentUser: FirebaseAuth.User? { Auth.auth().currentUser }

    // MARK: - Google Sign-In + Role Assignment
    func signInWithGoogle(presenting viewController: UIViewController,
                          completion: @escaping (Result<(FirebaseAuth.User, UserRole), Error>) -> Void) {

        guard let clientID = FirebaseApp.app()?.options.clientID else {
            completion(.failure(AuthError.missingClientID))
            return
        }

        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = config

        GIDSignIn.sharedInstance.signIn(withPresenting: viewController) { result, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            guard let user = result?.user,
                  let idToken = user.idToken?.tokenString else {
                completion(.failure(AuthError.missingToken))
                return
            }

            let credential = GoogleAuthProvider.credential(
                withIDToken: idToken,
                accessToken: user.accessToken.tokenString
            )

            Auth.auth().signIn(with: credential) { authResult, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }

                guard let firebaseUser = authResult?.user else {
                    completion(.failure(AuthError.noFirebaseUser))
                    return
                }

                // Assign or fetch role
                RoleManager.shared.assignRole(to: firebaseUser) { roleResult in
                    switch roleResult {
                    case .success(let role):
                        completion(.success((firebaseUser, role)))
                    case .failure(let error):
                        completion(.failure(error))
                    }
                }
            }
        }
    }

    // MARK: - Restore Previous Sign In
    func restorePreviousSignIn(completion: @escaping (Result<(FirebaseAuth.User, UserRole), Error>) -> Void) {
        guard let currentUser = Auth.auth().currentUser else {
            completion(.failure(AuthError.noFirebaseUser))
            return
        }

        RoleManager.shared.fetchRole(for: currentUser.uid) { result in
            switch result {
            case .success(let role):
                completion(.success((currentUser, role)))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    // MARK: - Sign Out
    func signOut(completion: @escaping (Result<Void, Error>) -> Void) {
        do {
            GIDSignIn.sharedInstance.signOut()
            try Auth.auth().signOut()
            completion(.success(()))
        } catch {
            completion(.failure(error))
        }
    }

    // MARK: - Delete Admin Account
    func deleteAdminAccount(completion: @escaping (Result<Void, Error>) -> Void) {
        guard let user = Auth.auth().currentUser else {
            completion(.failure(AuthError.noFirebaseUser))
            return
        }

        // Step 1: Delete Firestore data (admin doc + all students)
        RoleManager.shared.deleteAdminAndAllStudents(adminUID: user.uid) { result in
            switch result {
            case .failure(let error):
                completion(.failure(error))

            case .success:
                // Step 2: Delete Firebase Auth account
                user.delete { error in
                    if let error = error {
                        completion(.failure(error))
                    } else {
                        GIDSignIn.sharedInstance.signOut()
                        completion(.success(()))
                    }
                }
            }
        }
    }
}

enum AuthError: LocalizedError {
    case missingClientID, missingToken, noFirebaseUser

    var errorDescription: String? {
        switch self {
        case .missingClientID:  return "Firebase client ID not found."
        case .missingToken:     return "Google ID token is missing."
        case .noFirebaseUser:   return "Firebase user not returned."
        }
    }
}

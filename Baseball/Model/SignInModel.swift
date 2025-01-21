//
//  SignInModel.swift
//  Baseball
//
//  Created by 곽현우 on 1/21/25.
//

import SwiftUI
import Combine
import FirebaseAuth
import FirebaseFirestore

// MARK: - Model
struct UserModel {
    let id: String
    let email: String
}

class SignInModel {
    private let db = Firestore.firestore()

    func fetchEmail(forID id: String, completion: @escaping (Result<String, Error>) -> Void) {
        db.collection("users")
            .whereField("id", isEqualTo: id)
            .getDocuments { snapshot, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }

                guard let document = snapshot?.documents.first,
                      let email = document.data()["email"] as? String else {
                    completion(.failure(NSError(domain: "SignIn", code: 404, userInfo: [NSLocalizedDescriptionKey: "등록되지 않은 아이디입니다."])))
                    return
                }
                completion(.success(email))
            }
    }

    func authenticateUser(email: String, password: String, completion: @escaping (Result<User, Error>) -> Void) {
        Auth.auth().signIn(withEmail: email, password: password) { authResult, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            if let user = authResult?.user {
                completion(.success(user))
            } else {
                completion(.failure(NSError(domain: "SignIn", code: 401, userInfo: [NSLocalizedDescriptionKey: "로그인에 실패했습니다."])))
            }
        }
    }
}

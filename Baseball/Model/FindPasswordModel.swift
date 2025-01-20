//
//  FindPasswordModel.swift
//  Baseball
//
//  Created by 곽현우 on 1/18/25.
//

import Foundation
import FirebaseFirestore
import FirebaseAuth

class FindPasswordModel {
    var id: String = ""
    var newPassword: String = ""
    var confirmPassword: String = ""

    private let db = Firestore.firestore()

    func isPasswordValid() -> Bool {
        return !newPassword.isEmpty && newPassword == confirmPassword
    }

    func checkIDExists(_ id: String, completion: @escaping (Bool, String?) -> Void) {
        db.collection("users")
            .whereField("id", isEqualTo: id)
            .getDocuments { querySnapshot, error in
                if let error = error {
                    print("Error checking ID: \(error.localizedDescription)")
                    completion(false, nil)
                    return
                }

                guard let document = querySnapshot?.documents.first else {
                    completion(false, nil) // ID 없음
                    return
                }

                // 이메일 주소 가져오기
                let email = document.data()["email"] as? String
                completion(true, email)
            }
    }

    func sendPasswordReset(to email: String, completion: @escaping (Bool, String?) -> Void) {
        Auth.auth().sendPasswordReset(withEmail: email) { error in
            if let error = error {
                completion(false, error.localizedDescription)
            } else {
                completion(true, nil)
            }
        }
    }
}

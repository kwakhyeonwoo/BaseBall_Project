//
//  SignUpViewModel.swift
//  Baseball
//
//  Created by 곽현우 on 12/31/24.
//

import Foundation
import FirebaseAuth
import FirebaseFirestore

class SignUpViewModel: ObservableObject {
    @Published var id: String = ""
    @Published var password: String = ""
    @Published var confirmPassword: String = ""
    @Published var email: String = ""
    @Published var showAlert: Bool = false
    @Published var isSignUpSuccessful: Bool = false
    @Published var alertMessage: String = ""
    
    private let db = Firestore.firestore()

    func handleSignUp() {
        guard !id.isEmpty, !password.isEmpty, !email.isEmpty else {
            alertMessage = "모든 필드를 입력해주세요."
            showAlert = true
            return
        }

        guard password == confirmPassword else {
            alertMessage = "비밀번호가 일치하지 않습니다."
            showAlert = true
            return
        }

        // 아이디 중복 확인
        checkIdDuplication { [weak self] isDuplicate in
            guard let self = self else { return }

            if isDuplicate {
                self.alertMessage = "중복된 아이디입니다."
                self.showAlert = true
            } else {
                // 아이디 중복이 없을 경우 Firebase Authentication과 Firestore에 저장
                self.registerUser()
            }
        }
    }

    private func checkIdDuplication(completion: @escaping (Bool) -> Void) {
        db.collection("users")
            .whereField("username", isEqualTo: id)
            .getDocuments { querySnapshot, error in
                if let error = error {
                    self.alertMessage = "중복 확인 오류: \(error.localizedDescription)"
                    self.showAlert = true
                    completion(false)
                    return
                }
                
                if let documents = querySnapshot?.documents, !documents.isEmpty {
                    // 중복된 아이디가 존재
                    completion(true)
                } else {
                    // 중복되지 않음
                    completion(false)
                }
            }
    }

    private func registerUser() {
        Auth.auth().createUser(withEmail: email, password: password) { [weak self] result, error in
            guard let self = self else { return }

            if let error = error {
                self.alertMessage = "회원가입 실패: \(error.localizedDescription)"
                self.showAlert = true
                return
            }

            guard let user = result?.user else { return }

            // Firestore에 사용자 데이터 저장
            self.saveUserData(userId: user.uid)
        }
    }

    private func saveUserData(userId: String) {
        let userData: [String: Any] = [
            "id": id,
            "password": password,
            "email": email,
            "createdAt": Timestamp(date: Date())
        ]

        db.collection("users").document(userId).setData(userData) { [weak self] error in
            guard let self = self else { return }

            if let error = error {
                self.alertMessage = "사용자 데이터 저장 실패: \(error.localizedDescription)"
                self.showAlert = true
                return
            }

            self.alertMessage = "회원가입이 완료되었습니다!"
            self.isSignUpSuccessful = true
            self.showAlert = true
        }
    }
}

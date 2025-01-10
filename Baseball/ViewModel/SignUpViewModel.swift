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

    // 중복 확인
    func checkIdDuplication() {
        // 아이디가 비어 있으면 중복 확인을 하지 않음
        guard !id.isEmpty else {
            alertMessage = "아이디를 입력해주세요."
            showAlert = true
            return
        }
        
        db.collection("users")
            .whereField("id", isEqualTo: id)
            .getDocuments { [weak self] querySnapshot, error in
                DispatchQueue.main.async {
                    if let error = error {
                        self?.alertMessage = "중복 확인 오류: \(error.localizedDescription)"
                        self?.showAlert = true
                        return
                    }
                    
                    if let documents = querySnapshot?.documents, !documents.isEmpty {
                        // 중복된 아이디가 존재
                        self?.alertMessage = "중복된 아이디입니다."
                        self?.showAlert = true
                    } else {
                        // 중복되지 않음
                        self?.alertMessage = "사용 가능한 아이디입니다."
                        self?.showAlert = true
                    }
                }
            }
    }

    // 회원가입 처리
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
        
        // 회원가입 진행
        registerUser()
    }

    // Firebase Authentication으로 사용자 등록
    func registerUser() {
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

    // Firestore에 사용자 데이터 저장
    private func saveUserData(userId: String) {
        let userData: [String: Any] = [
            "id": id,
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


// do {
//   let token = try await AppCheck.appCheck().token(forcingRefresh: false)
//
//    Get the raw App Check token string.
//   let tokenString = token.token
//
//    Include the App Check token with requests to your server.
//   let url = URL(string: "https://yourbackend.example.com/yourApiEndpoint")!
//   var request = URLRequest(url: url)
//   request.httpMethod = "GET"
//   request.setValue(tokenString, forHTTPHeaderField: "X-Firebase-AppCheck")
//
//   let task = URLSession.shared.dataTask(with: request) { data, response, error in
//        Handle response from your backend.
//   }
//   task.resume()
// } catch(let error) {
//   print("Unable to retrieve App Check token: \(error)")
//   return
// }
// 
//
//AppCheck.appCheck().limitedUseToken() { token, error in
//
//}

//
//  FindIdViewModel.swift
//  Baseball
//
//  Created by 곽현우 on 1/14/25.
//

import Foundation
import FirebaseFirestore

class FindIDViewModel: ObservableObject {
    @Published var model = FindIDModel()
    @Published var isVerificationCodeSent = false
    @Published var isVerified = false
    @Published var alertMessage: String = ""
    @Published var showAlert = false
    @Published var foundID: String = ""

    private let db = Firestore.firestore()
    private let verificationCodeLength = 6
    private var generatedCode: String = ""

    // 이메일 인증 코드 요청
    func requestVerificationCode() {
        guard isValidEmail(model.email) else {
            alertMessage = "유효한 이메일을 입력해주세요."
            showAlert = true
            return
        }

        // Firestore에서 이메일 확인
        db.collection("users")
            .whereField("email", isEqualTo: model.email)
            .getDocuments { [weak self] querySnapshot, error in
                DispatchQueue.main.async {
                    if let error = error {
                        self?.alertMessage = "서버 오류: \(error.localizedDescription)"
                        self?.showAlert = true
                        return
                    }

                    if let documents = querySnapshot?.documents, !documents.isEmpty {
                        // 이메일이 등록되어 있으면 인증번호 생성 및 전송
                        self?.generatedCode = self?.generateRandomCode(length: self?.verificationCodeLength ?? 6) ?? ""
                        self?.sendVerificationEmail(to: self?.model.email ?? "", code: self?.generatedCode ?? "") { success in
                            DispatchQueue.main.async {
                                if success {
                                    self?.isVerificationCodeSent = true
                                    self?.alertMessage = "인증번호가 이메일로 전송되었습니다."
                                } else {
                                    self?.alertMessage = "인증번호 전송에 실패했습니다. 다시 시도해주세요."
                                }
                                self?.showAlert = true
                            }
                        }
                    } else {
                        // 이메일이 등록되지 않은 경우
                        self?.alertMessage = "등록되지 않은 이메일입니다."
                        self?.showAlert = true
                    }
                }
            }
    }

    // 인증번호 확인
    func verifyCode() {
        guard model.verificationCode == generatedCode else {
            alertMessage = "인증번호가 올바르지 않습니다."
            showAlert = true
            return
        }

        db.collection("users")
            .whereField("email", isEqualTo: model.email)
            .getDocuments { [weak self] querySnapshot, error in
                DispatchQueue.main.async {
                    if let error = error {
                        self?.alertMessage = "아이디 찾기 실패: \(error.localizedDescription)"
                        self?.showAlert = true
                        return
                    }

                    if let documents = querySnapshot?.documents, let document = documents.first {
                        self?.foundID = document.data()["id"] as? String ?? "알 수 없는 아이디"
                        self?.alertMessage = "아이디: \(self?.foundID ?? "없음")"
                    } else {
                        self?.alertMessage = "해당 이메일에 연결된 아이디를 찾을 수 없습니다."
                    }
                    self?.showAlert = true
                }
            }
    }

    // 이메일 형식 검증
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        return NSPredicate(format: "SELF MATCHES %@", emailRegex).evaluate(with: email)
    }

    // 랜덤 코드 생성
    private func generateRandomCode(length: Int) -> String {
        return String((0..<length).map { _ in "0123456789".randomElement()! })
    }

    // 이메일 전송 함수 (Firebase Cloud Function 호출)
    private func sendVerificationEmail(to email: String, code: String, completion: @escaping (Bool) -> Void) {
        guard let url = URL(string: "https://sendverificationcode-csknue227q-uc.a.run.app") else {
            completion(false)
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let body: [String: Any] = ["email": email, "code": code]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body, options: [])

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error sending email: \(error.localizedDescription)")
                completion(false)
                return
            }

            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                completion(true)
            } else {
                completion(false)
            }
        }.resume()
    }
}

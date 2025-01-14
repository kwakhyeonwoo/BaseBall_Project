//
//  FindIdViewModel.swift
//  Baseball
//
//  Created by 곽현우 on 1/14/25.
//

import Foundation

class FindIDViewModel: ObservableObject {
    @Published var model = FindIDModel()
    @Published var isVerificationCodeSent = false
    @Published var isVerified = false
    @Published var alertMessage: String = ""
    @Published var showAlert = false
    
    private let verificationCodeLength = 6
    private var generatedCode: String = ""
    
    // 이메일 인증 코드 요청
    func requestVerificationCode() {
        guard isValidEmail(model.email) else {
            alertMessage = "유효한 이메일을 입력해주세요."
            showAlert = true
            return
        }
        
        // 랜덤 인증번호 생성
        generatedCode = String((0..<verificationCodeLength).map { _ in "0123456789".randomElement()! })
        
        sendVerificationEmail(to: model.email, code: generatedCode) { [weak self] success in
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
    }
    
    // 인증번호 확인
    func verifyCode() {
        if model.verificationCode == generatedCode {
            isVerified = true
            alertMessage = "인증이 완료되었습니다!"
        } else {
            alertMessage = "인증번호가 올바르지 않습니다."
        }
        showAlert = true
    }
    
    // 이메일 형식 검증
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        return NSPredicate(format: "SELF MATCHES %@", emailRegex).evaluate(with: email)
    }
    
    // 이메일 전송 함수 (Cloud Functions 호출)
    private func sendVerificationEmail(to email: String, code: String, completion: @escaping (Bool) -> Void) {
        guard let url = URL(string: "https://console.cloud.google.com/gcr/images/baseball-642ed/us/gcf") else {
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

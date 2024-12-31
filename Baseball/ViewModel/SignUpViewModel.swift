//
//  SignUpViewModel.swift
//  Baseball
//
//  Created by 곽현우 on 12/31/24.
//

import SwiftUI

class SignUpViewModel: ObservableObject {
    @Published var id: String = ""
    @Published var email: String = ""
    @Published var password: String = ""
    @Published var confirmPassword: String = ""
    @Published var alertMessage: String = ""
    @Published var showAlert: Bool = false
    @Published var isSignUpSuccessful: Bool = false
    
    // MARK: 아이디 중복 여부
    func checkIdDuplication() {
        if id.isEmpty {
            alertMessage = "아이디를 입력해주세요."
        } else if id == "polla" { // 예시
            alertMessage = "이미 사용 중인 아이디입니다."
        } else {
            alertMessage = "사용 가능한 아이디입니다."
        }
        showAlert = true
    }
    
    // MARK: 회원가입 로직
    func handleSignUp() {
        guard !id.isEmpty, !email.isEmpty, !password.isEmpty, !confirmPassword.isEmpty else {
            alertMessage = "모든 필드를 입력하세요."
            showAlert = true
            return
        }
        
        guard password == confirmPassword else {
            alertMessage = "비밀번호가 일치하지 않습니다."
            showAlert = true
            return
        }
        
        alertMessage = "회원가입 성공!"
        showAlert = true
        isSignUpSuccessful = true
    }
}


//
//  FindPasswordViewModel.swift
//  Baseball
//
//  Created by 곽현우 on 1/18/25.
//

import Foundation

class FindPasswordViewModel: ObservableObject {
    @Published var model = FindPasswordModel()
    @Published var alertMessage: String = ""
    @Published var showAlert = false

    func validateIDAndSendResetEmail() {
        model.checkIDExists(model.id) { [weak self] exists, email in
            DispatchQueue.main.async {
                if exists, let email = email {
                    self?.sendPasswordResetEmail(to: email)
                } else {
                    self?.alertMessage = "존재하지 않는 아이디입니다."
                    self?.showAlert = true
                }
            }
        }
    }

    func sendPasswordResetEmail(to email: String) {
        model.sendPasswordReset(to: email) { [weak self] success, error in
            DispatchQueue.main.async {
                if success {
                    self?.alertMessage = "비밀번호 재설정 이메일이 \(email)로 전송되었습니다."
                } else {
                    self?.alertMessage = error ?? "비밀번호 재설정 이메일 전송에 실패했습니다."
                }
                self?.showAlert = true
            }
        }
    }
}

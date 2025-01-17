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
    @Published var foundID: String = ""

    private var generatedCode: String = ""

    // 이메일 인증 코드 요청
    func requestVerificationCode() {
        guard model.isValidEmail(model.email) else {
            alertMessage = "유효한 이메일을 입력해주세요."
            showAlert = true
            return
        }

        // Firestore에서 이메일 확인
        model.fetchID(for: model.email) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    // 이메일이 등록되어 있으면 인증번호 생성 및 전송
                    self?.generatedCode = self?.model.generateRandomCode(length: 6) ?? ""
                    self?.model.sendVerificationEmail(to: self?.model.email ?? "", code: self?.generatedCode ?? "") { success in
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
                case .failure:
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

        // 인증 완료 후 ID 표시
        model.fetchID(for: model.email) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let id):
                    self?.foundID = id
                    self?.alertMessage = "아이디: \(id)"
                case .failure(let error):
                    self?.alertMessage = error.localizedDescription
                }
                self?.showAlert = true
            }
        }
    }
}

//
//  SignInViewModel.swift
//  Baseball
//
//  Created by 곽현우 on 1/2/25.
//

import SwiftUI
import Combine
import FirebaseAuth
import FirebaseFirestore

class SignInViewModel: ObservableObject {
    @Published var ID: String = ""
    @Published var PW: String = ""
    @Published var isTeamSelectActive: Bool = false
    @Published var showAlert: Bool = false
    @Published var alertMessage: String = ""
    @Published var isLoggedIn: Bool = false

    private var cancellables = Set<AnyCancellable>()
    private let authProvider: AuthProvider
    private let model = SignInModel()

    init(authProvider: AuthProvider) {
        self.authProvider = authProvider

        // 로그인 상태를 관찰
        if let googleAuth = authProvider as? GoogleAuth {
            googleAuth.$isSignedIn
                .receive(on: DispatchQueue.main)
                .sink { [weak self] isSignedIn in
                    if isSignedIn {
                        self?.isTeamSelectActive = true
                    }
                }
                .store(in: &cancellables)
        }
    }

    func signIn() {
        // ID와 PW가 비어 있는지 확인
        guard !ID.isEmpty, !PW.isEmpty else {
            alertMessage = "아이디와 비밀번호를 입력해주세요."
            showAlert = true
            return
        }

        // Firestore에서 ID로 이메일 찾기
        model.fetchEmail(forID: ID) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let email):
                    self?.authenticate(email: email)
                case .failure(let error):
                    self?.alertMessage = error.localizedDescription
                    self?.showAlert = true
                }
            }
        }
    }

    private func authenticate(email: String) {
        model.authenticateUser(email: email, password: PW) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let user):
                    self?.alertMessage = "로그인 성공! 환영합니다, \(user.email ?? "사용자")"
                    self?.isTeamSelectActive = true
                    self?.isLoggedIn = true
                case .failure(let error):
                    self?.alertMessage = ("비밀번호가 틀렸습니다.")
                    self?.showAlert = true
                }
            }
        }
    }

    func kakaoLogin() {
        KakaoAuth.shared.loginWithKakao { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let token):
                    self.alertMessage = "카카오 로그인 성공! 토큰: \(token)"
                    self.isTeamSelectActive = true
                case .failure(let error):
                    self.alertMessage = "카카오 로그인 실패: \(error.localizedDescription)"
                }
                self.showAlert = true
            }
        }
    }

    func googleLogin() {
        authProvider.signIn()
    }

    func logOut() {
        authProvider.signOut()
    }
}

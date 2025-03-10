//
//  FindPassword.swift
//  Baseball
//
//  Created by 곽현우 on 12/30/24.
//

import SwiftUI

struct FindPassword: View {
    @StateObject private var viewModel = FindPasswordViewModel()

    var body: some View {
        NavigationStack {
            VStack {
                idInputSection()
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)

                actionButton()
                    .padding(.horizontal, 20)

                Spacer()
            }
            .padding(.top, 40)
            .alert(isPresented: $viewModel.showAlert) {
                Alert(
                    title: Text("알림"),
                    message: Text(viewModel.alertMessage),
                    dismissButton: .default(Text("확인"))
                )
            }
        }
    }

    // MARK: - 아이디 입력 섹션
    func idInputSection() -> some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("아이디를 입력해주세요")
                .font(.headline)
                .foregroundColor(.black)

            TextField("아이디", text: $viewModel.model.id)
                .padding()
                .background(Color.white)
                .cornerRadius(10)
                .shadow(color: .gray.opacity(0.2), radius: 5, x: 0, y: 2)
                .autocapitalization(.none)
        }
    }

    // MARK: - 버튼 섹션
    func actionButton() -> some View {
        Button(action: {
            viewModel.validateIDAndSendResetEmail()
        }) {
            Text("비밀번호 재설정 이메일 보내기")
                .fontWeight(.bold)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
        }
    }
}
#Preview {
    FindPassword()
}

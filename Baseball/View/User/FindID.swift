//
//  FindID.swift
//  Baseball
//
//  Created by 곽현우 on 12/30/24.
//

import SwiftUI

struct FindID: View {
    @StateObject private var viewModel = FindIDViewModel()
    
    var body: some View {
        NavigationStack {
            VStack {
                headerSection()
                    .padding(.bottom, 30)
                
                emailInputSection()
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                
                if viewModel.isVerificationCodeSent {
                    verificationCodeSection()
                        .padding(.horizontal, 20)
                        .padding(.bottom, 20)
                }
                
                actionButtons()
                    .padding(.horizontal, 20)
                
                Spacer()
            }
            .padding(.top, 40)
            .alert(isPresented: $viewModel.showAlert) {
                if viewModel.isVerified {
                    return Alert(
                        title: Text("아이디 찾기 성공"),
                        message: Text("아이디: \(viewModel.foundID)"),
                        dismissButton: .default(Text("확인")) {
                            viewModel.isSignInActive = true // "확인" 버튼에서 상태 변경
                        }
                    )
                } else {
                    return Alert(
                        title: Text("알림"),
                        message: Text(viewModel.alertMessage),
                        dismissButton: .default(Text("확인"))
                    )
                }
            }
        }
    }
    
    // MARK: - 헤더 섹션
    func headerSection() -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("아이디 찾기")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.black)
        }
    }
    
    // MARK: - 이메일 입력 섹션
    func emailInputSection() -> some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("이메일을 입력해주세요")
                .font(.headline)
                .foregroundColor(.black)
            
            TextField("", text: $viewModel.model.email)
                .padding()
                .background(Color.white)
                .cornerRadius(10)
                .shadow(color: .gray.opacity(0.2), radius: 5, x: 0, y: 2)
                .autocapitalization(.none)
                .keyboardType(.emailAddress)
        }
    }
    
    // MARK: - 인증번호 입력 섹션
    func verificationCodeSection() -> some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("인증번호를 입력해주세요")
                .font(.headline)
                .foregroundColor(.black)
            
            TextField("6자리 인증번호", text: $viewModel.model.verificationCode)
                .padding()
                .background(Color.white)
                .cornerRadius(10)
                .shadow(color: .gray.opacity(0.2), radius: 5, x: 0, y: 2)
                .keyboardType(.numberPad)
            
        }
    }
    
    // MARK: - 버튼 섹션
    func actionButtons() -> some View {
        VStack(spacing: 15) {
            Button(action: {
                viewModel.requestVerificationCode()
            }) {
                Text("인증번호 요청")
                    .fontWeight(.bold)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(viewModel.isVerificationCodeSent ? Color.gray : Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .disabled(viewModel.isVerificationCodeSent)
            
            if viewModel.isVerificationCodeSent {
                Button(action: {
                    viewModel.verifyCode()
                }) {
                    Text("인증번호 확인")
                        .fontWeight(.bold)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
            }
        }
    }
}

#Preview {
    FindID()
}

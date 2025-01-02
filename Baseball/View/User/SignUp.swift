//
//  SignUp.swift
//  Baseball
//
//  Created by 곽현우 on 12/28/24.
//

import SwiftUI

struct SignUp: View {
    @StateObject private var viewmodel = SignUpViewModel()
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 25) {
                // 제목
                Text("회원정보를 입력해주세요")
                    .font(.title2)
                    .padding(.bottom, 20)
                
                customIDInputField()
                passwordInputFields()
                emailInputField()
                actionButtons()
                Spacer()
            }
            .padding()
            .frame(maxWidth: 500)
            .background(Color(uiColor: .systemGroupedBackground))
            .navigationTitle("회원가입")
            .alert(isPresented: $viewmodel.showAlert) {
                if viewmodel.isSignUpSuccessful {
                    // 회원가입 성공 시 alert
                    return Alert(
                        title: Text("알림"),
                        message: Text(viewmodel.alertMessage),
                        dismissButton: .default(Text("확인")) {
                            presentationMode.wrappedValue.dismiss()
                        }
                    )
                } else {
                    // 일반 alert
                    return Alert(
                        title: Text("알림"),
                        message: Text(viewmodel.alertMessage),
                        dismissButton: .default(Text("확인"))
                    )
                }
            }
        }
    }
    
    // MARK: 아이디, 중복확인 버튼
    func customIDInputField() -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("아이디")
                .font(.headline)
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(uiColor: .secondarySystemBackground))
                    .shadow(color: .gray.opacity(0.2), radius: 4, x: 0, y: 2)
                
                HStack {
                    TextField("아이디를 입력하세요", text: $viewmodel.id)
                        .padding(.leading, 15)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                    
                    Button(action: {
                        viewmodel.checkIdDuplication()
                    }) {
                        Text("중복 확인")
                            .font(.footnote)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(6)
                    }
                    .padding(.trailing, 10)
                }
            }
            .frame(height: 50)
        }
    }
    
    // MARK: 비밀번호, 비밀번호 확인
    func passwordInputFields() -> some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("비밀번호")
                .font(.headline)
            SecureField("비밀번호를 입력하세요", text: $viewmodel.password)
                .padding()
                .background(Color(uiColor: .secondarySystemBackground))
                .cornerRadius(10)
                .shadow(color: .gray.opacity(0.2), radius: 4, x: 0, y: 2)
            Text("비밀번호 확인")
                .font(.headline)
            SecureField("비밀번호를 확인하세요", text: $viewmodel.confirmPassword)
                .padding()
                .background(Color(uiColor: .secondarySystemBackground))
                .cornerRadius(10)
                .shadow(color: .gray.opacity(0.2), radius: 4, x: 0, y: 2)
        }
    }
    
    // MARK: 이메일
    func emailInputField() -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("이메일")
                .font(.headline)
            TextField("이메일을 입력하세요", text: $viewmodel.email)
                .padding()
                .background(Color(uiColor: .secondarySystemBackground))
                .cornerRadius(10)
                .keyboardType(.emailAddress)
                .shadow(color: .gray.opacity(0.2), radius: 4, x: 0, y: 2)
        }
    }
    
    // MARK: 가입하기, 취소 버튼
    func actionButtons() -> some View {
        HStack(spacing: 20) {
            
            Button(action: {
                presentationMode.wrappedValue.dismiss()
            }) {
                Text("취소")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.red)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    .shadow(color: .red.opacity(0.2), radius: 4, x: 0, y: 2)
            }
            
            Button(action: {
                viewmodel.handleSignUp()
            }) {
                Text("가입하기")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    .shadow(color: .blue.opacity(0.2), radius: 4, x: 0, y: 2)
            }
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    SignUp()
}

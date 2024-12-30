//
//  login_main.swift
//  Baseball_Project
//
//  Created by 곽현우 on 12/28/24.
//

import SwiftUI

struct SignIn: View {
    @State private var ID: String = ""
    @State private var PW: String = ""
    @State private var isTeamSelectActive: Bool = false // TeamSelect 화면 이동 플래그
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                viewText()
                idPasswordInputField()
                loginButton()
                actionButtons()
                socialLoginButtons()
                
                NavigationLink(destination: TeamSelect(), isActive: $isTeamSelectActive) {
                    EmptyView()
                }
                
            }
            .padding()
            .frame(maxWidth: 500)
        }
    }
    
    // 1. 왼쪽 정렬된 텍스트
    func viewText() -> some View {
        Text("안녕하세요 :)\n누구나 야구를 입니다.")
            .font(.title)
            .fontWeight(.bold)
            .padding(.bottom, 20)
            .frame(maxWidth: .infinity, alignment: .leading) // 왼쪽 정렬
    }
    
    // 2. ID, PW 입력 필드
    func idPasswordInputField() -> some View {
        VStack(spacing: 15) {
            // ID 입력
            TextField("아이디를 입력하세요", text: $ID)
                .padding()
                .background(Color(uiColor: .secondarySystemBackground))
                .cornerRadius(8)
                .shadow(color: .gray.opacity(0.3), radius: 5, x: 0, y: 2)
                .autocapitalization(.none)
                .disableAutocorrection(true)
            
            // PW 입력
            SecureField("비밀번호를 입력하세요", text: $PW)
                .padding()
                .background(Color(uiColor: .secondarySystemBackground))
                .cornerRadius(8)
                .shadow(color: .gray.opacity(0.3), radius: 5, x: 0, y: 2)
        }
    }
    
    // 3. 로그인 버튼
    func loginButton() -> some View {
        Button(action: {
            isTeamSelectActive = true // 로그인 로직 추가 가능
        }) {
            Text("로그인")
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(8)
                .shadow(color: .blue.opacity(0.3), radius: 5, x: 0, y: 2)
        }
    }
    
    // 4. 회원가입, 아이디 찾기, 비밀번호 찾기 버튼
    func actionButtons() -> some View {
        HStack {
            NavigationLink(destination: FindID()) {
                Text("아이디 찾기")
                    .font(.footnote)
                    .foregroundColor(.blue)
            }
            
            Divider()
                .frame(height: 15)
                .background(Color.gray)
            
            NavigationLink(destination: FindPassword()) {
                Text("비밀번호 찾기")
                    .font(.footnote)
                    .foregroundColor(.blue)
            }
            
            Divider()
                .frame(height: 15)
                .background(Color.gray)
            
            NavigationLink(destination: SignUp()) {
                Text("회원가입")
                    .font(.footnote)
                    .foregroundColor(.blue)
            }
        }
        .padding(.top, 10)
        .frame(maxWidth: .infinity) // 중앙 정렬을 위한 설정
    }
    
    // 5. 카카오 로그인, 구글 로그인 버튼
    func socialLoginButtons() -> some View {
        VStack(spacing: 15) {
            Button(action: {
                // 카카오 로그인 액션
            }) {
                HStack {
                    Image(systemName: "message.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 20, height: 20)
                    Spacer()
                    Text("카카오로 계속하기")
                    Spacer()
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.yellow)
                .foregroundColor(.black)
                .cornerRadius(8)
                .shadow(color: .gray.opacity(0.3), radius: 5, x: 0, y: 2)
            }
            
            Button(action: {
                // 구글 로그인 액션
            }) {
                HStack(spacing: 15){
                    Image("Google")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 20, height: 20)
                    Spacer()
                    Text("Google로 계속하기")
                    Spacer()
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.white)
                .foregroundColor(.black)
                .cornerRadius(8)
                .shadow(color: .gray.opacity(0.3), radius: 5, x: 0, y: 2)
                
            }
        }
        .padding(.top, 20) // 카카오/구글 버튼 사이에 공간 추가
    }
}

#Preview {
    SignIn()
}

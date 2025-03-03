//
//  UploadSongTitleView.swift
//     
//
//  Created by 곽현우 on 3/1/25.
//

import SwiftUI
import FirebaseAuth

struct UploadSongTitleView: View {
    let selectedTeam: String
    let selectedTeamImage: String
    let videoURL: URL?

    @State private var title: String = ""
    @State private var navigateToCheckAllVideo = false
    @State private var showAlert = false
    @State private var alertMessage = ""

    var body: some View {
        VStack {
            Text("응원가의 제목을 지어주세요!")
                .font(.title)
                .fontWeight(.bold)
                .padding()

            TextField("응원가 제목 입력", text: $title)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()

            Button("확인") {
                guard let validURL = videoURL else {
                    alertMessage = "비디오 URL을 찾을 수 없습니다. 다시 시도해주세요."
                    showAlert = true
                    return
                }

                print("✅ 최종 비디오 URL: \(validURL.absoluteString)")

                checkUserAndUpload(title: title, videoURL: validURL)
            }

            NavigationLink(destination: CheckAllVideo(selectedTeam: selectedTeam, selectedTeamImage: selectedTeamImage), isActive: $navigateToCheckAllVideo) {
                EmptyView()
            }
        }
        .padding()
        .alert(isPresented: $showAlert) {
            Alert(title: Text("알림"), message: Text(alertMessage), dismissButton: .default(Text("확인")))
        }
    }

    private func checkUserAndUpload(title: String, videoURL: URL) {
        if let user = Auth.auth().currentUser {
            print("✅ 로그인한 사용자: \(user.email ?? "익명")")
            uploadToFirestore(title: title, videoURL: videoURL, uploader: user.email ?? "익명")
        } else {
            print("❌ 로그인 정보가 없습니다. 다시 로그인 시도")
            Auth.auth().signInAnonymously { authResult, error in
                if let error = error {
                    print("❌ 익명 로그인 실패: \(error.localizedDescription)")
                    alertMessage = "로그인 오류가 발생했습니다."
                    showAlert = true
                    return
                }

                if let user = authResult?.user {
                    print("✅ 익명 로그인 성공: \(user.uid)")
                    uploadToFirestore(title: title, videoURL: videoURL, uploader: "익명")
                } else {
                    alertMessage = "로그인 정보를 확인할 수 없습니다."
                    showAlert = true
                }
            }
        }
    }

    private func uploadToFirestore(title: String, videoURL: URL, uploader: String) {
        UploadedSongsManager().uploadVideo(
            title: title,
            videoURL: videoURL,
            selectedTeam: selectedTeam
        ) { success in
            if success {
                navigateToCheckAllVideo = true
            } else {
                alertMessage = "업로드에 실패했습니다."
                showAlert = true
            }
        }
    }
}

//#Preview {
//    UploadSongTitleView()
//}

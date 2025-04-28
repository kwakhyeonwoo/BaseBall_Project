//
//  UploadSongTitleView.swift
//
//
//  Created by 곽현우 on 3/1/25.
//

import SwiftUI

struct UploadSongTitleView: View {
    let selectedTeam: String
    let selectedTeamImage: String
    let videoURL: URL?

    @State private var title: String = ""
    @State private var navigateToCheckAllVideo = false
    @State private var showAlert = false
    @State private var alertMessage = ""

    @StateObject private var viewModel = CheckAllVideoViewModel()

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
                navigateToCheckAllVideo = true

                viewModel.checkUserAndUpload(title: title, videoURL: validURL, selectedTeam: selectedTeam) { success in
                    if success {
                        print("✅ 업로드 성공")
                    } else {
                        print("❌ 업로드 실패")
                    }
                }
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
}

//#Preview {
//    UploadSongTitleView()
//}

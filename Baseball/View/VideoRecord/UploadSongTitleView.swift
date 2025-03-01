//
//  UploadSongTitleView.swift
//     
//
//  Created by 곽현우 on 3/1/25.
//

import SwiftUI
import FirebaseFirestore

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
                print("✅ 제목 입력: \(title)")  // ✅ 제목 로그 확인
                print("✅ 전달된 비디오 URL: \(String(describing: videoURL))")  // ✅ URL 로그 확인
                
                guard let videoURL = videoURL else {
                    alertMessage = "비디오 URL을 찾을 수 없습니다."
                    showAlert = true
                    return
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

    private func saveSongToFirestore(videoURL: URL) {
//        guard let videoURL = videoURL else {
//            alertMessage = "잘못된 비디오 URL입니다."
//            showAlert = true
//            return
//        }

        print("✅ Firestore에 저장할 비디오 URL: \(videoURL.absoluteString)")
        
        let encodedVideoURL = videoURL.absoluteString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? videoURL.absoluteString
            print("✅ Firestore에 저장할 비디오 URL: \(encodedVideoURL)")
        
        let firestoreService = Firestore.firestore()
        let newSong: [String: Any] = [
            "title": title,
            "uploader": "익명",
            "videoURL": videoURL.absoluteString,
            "team": selectedTeam,  // Firestore에 팀 정보 저장
            "timestamp": Timestamp(date: Date())
        ]
        
        firestoreService.collection("uploadedSongs").addDocument(data: newSong) { error in
            if let error = error {
                print("❌ Firestore 업로드 실패: \(error.localizedDescription)")
                alertMessage = "업로드에 실패했습니다."
                showAlert = true
            } else {
                print("✅ Firestore 업로드 성공: \(title)")
                navigateToCheckAllVideo = true
            }
        }
    }
}


//#Preview {
//    UploadSongTitleView()
//}

//
//  CheckAllVideo.swift
//
//
//  Created by 곽현우 on 2/27/25.
//

import AVKit
import SwiftUI
import FirebaseFirestore
import FirebaseStorage

// 응원가 확인하기 뷰
struct CheckAllVideo: View {
    let selectedTeam: String
    let selectedTeamImage: String
    @State private var selectedCategory: UploadedSongCategory = .uploaded
    @State private var uploadedSongs: [UploadedSong] = []
    @StateObject private var viewModel = CheckAllVideoViewModel()
    private let db = Firestore.firestore()
    
    var body: some View {
        NavigationView {
            VStack {
                categoryPicker()
                songListView()
            }
            .padding()
            .onAppear {
                loadUploadedSongs()
            }
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("RefreshUploadedSongs"))) { _ in
                loadUploadedSongs()
            }
        }
    }
    
    // MARK: 업로드 / 인기 응원가 카테고리
    private func categoryPicker() -> some View {
        Picker("Category", selection: $selectedCategory) {
            Text("업로드 응원가").tag(UploadedSongCategory.uploaded)
            Text("인기 응원가").tag(UploadedSongCategory.popular)
        }
        .pickerStyle(SegmentedPickerStyle())
        .padding()
        .onChange(of: selectedCategory) { _ in
            loadUploadedSongs()
        }
    }
    
    // MARK: 응원가 리스트 뷰
    private func songListView() -> some View {
        ScrollView {
            VStack(spacing: 15) {
                ForEach(uploadedSongs) { song in
                    songCard(song: song)
                        .onTapGesture {
                            playVideo(song: song) // ✅ 동영상 클릭 시 재생
                        }
                }
            }
            .padding()
        }
    }
    
    // MARK: 개별 응원가 카드 UI
    private func songCard(song: UploadedSong) -> some View {
        HStack {
            Image(selectedTeamImage)
                .resizable()
                .scaledToFit()
                .frame(width: 50, height: 50)
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 5) {
                Text(song.uploader)
                    .font(.footnote)
                    .foregroundColor(.gray)
                
                Text(song.title)
                    .font(.headline)
                    .foregroundColor(.primary)
            }
            
            Spacer()

            VStack {
                Button(action: {
                    viewModel.toggleLike(for: song)
                }) {
                    Image(systemName: viewModel.likedSongs.contains(song.id) ? "heart.fill" : "heart")
                        .foregroundColor(viewModel.likedSongs.contains(song.id) ? .red : .gray)
                        .font(.title2)
                }
                
                Text("\(viewModel.likeCounts[song.id, default: 0])")
                    .font(.footnote)
                    .foregroundColor(.gray)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, minHeight: 80) // ✅ 카드 크기 통일 (가로/세로)
        .background(Color(uiColor: .secondarySystemBackground))
        .cornerRadius(10)
        .shadow(radius: 2)
    }

    // MARK: Firestore에서 데이터 가져오기
    private func loadUploadedSongs() {
        db.collection("uploadedSongs").getDocuments { snapshot, error in
            guard let documents = snapshot?.documents, error == nil else {
                print("Error fetching uploaded songs: \(error?.localizedDescription ?? "Unknown error")")
                return
            }
            
            DispatchQueue.main.async {
                self.uploadedSongs = documents.compactMap { document in
                    let data = document.data()
                    return UploadedSong(
                        id: document.documentID,
                        title: data["title"] as? String ?? "Unknown Title",
                        uploader: data["uploader"] as? String ?? "익명",
                        videoURL: data["videoURL"] as? String ?? "" // ✅ Firestore에서 가져온 videoURL 추가
                    )
                }
            }
        }
    }

    // MARK: 동영상 재생 함수 (AVPlayer)
    private func playVideo(song: UploadedSong) {
        guard let videoURL = URL(string: song.videoURL) else {
            print("❌ 잘못된 URL: \(song.videoURL)")
            return
        }

        print("✅ AVPlayer에 전달할 Storage URL: \(videoURL.absoluteString)")

        DispatchQueue.main.async {
            let asset = AVURLAsset(url: videoURL)
            let playerItem = AVPlayerItem(asset: asset)
            playerItem.preferredForwardBufferDuration = 5 // ✅ HLS 네트워크 버퍼링 설정

            let player = AVPlayer(playerItem: playerItem)
            let playerController = AVPlayerViewController()
            playerController.player = player

            // ✅ AVPlayerViewController를 올바르게 실행
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let rootViewController = windowScene.windows.first?.rootViewController {
                rootViewController.present(playerController, animated: true) {
                    player.play()
                }
            } else {
                print("❌ AVPlayer를 실행할 수 없습니다.")
            }
        }
    }
}

// MARK: Firestore에서 가져오는 데이터 모델
struct UploadedSong: Identifiable {
    let id: String
    let title: String
    let uploader: String
    let videoURL: String // ✅ Firestore에서 동영상 URL을 가져오기 위해 추가
}

enum UploadedSongCategory {
    case uploaded
    case popular
}


//#Preview {
//    CheckAllVideo()
//}

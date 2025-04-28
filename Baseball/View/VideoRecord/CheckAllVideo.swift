//
//  CheckAllVideo.swift
//
//
//  Created by 곽현우 on 2/27/25.
//

import SwiftUI
import FirebaseFirestore
import FirebaseStorage
import AVKit

struct CheckAllVideo: View {
    let selectedTeam: String
    let selectedTeamImage: String

    @State private var uploadedSongs: [UploadedSong] = []
    @State private var selectedCategory: UploadedSongCategory = .uploaded
    @StateObject private var viewModel = CheckAllVideoViewModel()
    private let db = Firestore.firestore()

    var body: some View {
        NavigationView {
            VStack {
                Picker("Category", selection: $selectedCategory) {
                    Text("업로드 응원가").tag(UploadedSongCategory.uploaded)
                    Text("인기 응원가").tag(UploadedSongCategory.popular)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()
                .onChange(of: selectedCategory) { _ in
                    loadUploadedSongs()
                }

                ScrollView {
                    VStack(spacing: 15) {
                        ForEach(uploadedSongs) { song in
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
                            .background(Color(.secondarySystemBackground))
                            .cornerRadius(10)
                            .shadow(radius: 2)
                            .onTapGesture {
                                playVideo(song: song)
                            }
                        }
                    }
                    .padding()
                }
            }
            .onAppear {
                loadUploadedSongs()
            }
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("RefreshUploadedSongs"))) { _ in
                loadUploadedSongs()
            }
        }
    }

    private func loadUploadedSongs() {
        db.collection("uploadedSongs").getDocuments { snapshot, error in
            guard let documents = snapshot?.documents, error == nil else {
                print("❌ Firestore 데이터 불러오기 실패: \(error?.localizedDescription ?? "Unknown error")")
                return
            }

            DispatchQueue.main.async {
                self.uploadedSongs = documents.compactMap { doc in
                    let data = doc.data()
                    return UploadedSong(
                        id: doc.documentID,
                        title: data["title"] as? String ?? "Unknown",
                        uploader: data["uploader"] as? String ?? "익명",
                        videoURL: data["videoURL"] as? String ?? "",
                        thumbnailURL: data["videoURL"] as? String ?? ""
                    )
                }
            }
        }
    }

    private func playVideo(song: UploadedSong) {
        var urlString = song.videoURL
        guard let originalURL = URL(string: song.videoURL.replacingOccurrences(of: ":443", with: "")) else {
            print("❌ 잘못된 URL")
            return
        }

        print("✅ AVPlayer에 전달할 Storage URL: \(originalURL.absoluteString)")

        DispatchQueue.main.async {
            let asset = AVURLAsset(url: originalURL)
            let playerItem = AVPlayerItem(asset: asset)
            playerItem.preferredForwardBufferDuration = 2
            asset.resourceLoader.preloadsEligibleContentKeys = false

            let player = AVPlayer(playerItem: playerItem)
            let playerController = AVPlayerViewController()
            playerController.player = player

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

//#Preview {
//    CheckAllVideo()
//}

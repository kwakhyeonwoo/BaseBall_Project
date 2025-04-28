//
//  CheckAllVideoViewModel.swift
//     
//
//  Created by 곽현우 on 3/10/25.
//

import SwiftUI
import FirebaseFirestore
import FirebaseAuth
import AVKit

class CheckAllVideoViewModel: ObservableObject {
    @Published var uploadedSongs: [UploadedSong] = []
    @Published var likedSongs: Set<String> = []
    @Published var likeCounts: [String: Int] = [:]

    private let db = Firestore.firestore()
    private let likedSongsKey = "likedSongs"
    private let likeCountsKey = "likeCounts"

    init() {
        loadLikedSongs()
        loadLikeCounts()
    }

    // MARK: - 좋아요 기능
    func toggleLike(for song: UploadedSong) {
        DispatchQueue.main.async {
            if self.likedSongs.contains(song.id) {
                self.likedSongs.remove(song.id)
                self.likeCounts[song.id] = 0
            } else {
                self.likedSongs.insert(song.id)
                self.likeCounts[song.id] = 1
            }
            self.saveLikedSongs()
            self.saveLikeCounts()
        }
    }

    private func saveLikedSongs() {
        let likedArray = Array(likedSongs)
        UserDefaults.standard.set(likedArray, forKey: likedSongsKey)
    }

    private func loadLikedSongs() {
        if let savedLikedSongs = UserDefaults.standard.array(forKey: likedSongsKey) as? [String] {
            likedSongs = Set(savedLikedSongs)
        }
    }

    private func saveLikeCounts() {
        UserDefaults.standard.set(likeCounts, forKey: likeCountsKey)
    }

    private func loadLikeCounts() {
        if let savedLikeCounts = UserDefaults.standard.dictionary(forKey: likeCountsKey) as? [String: Int] {
            likeCounts = savedLikeCounts
        }
    }

    // MARK: - 업로드된 응원가 불러오기
    func loadUploadedSongs() {
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
                        thumbnailURL: data["thumbnailURL"] as? String ?? ""
                    )
                }
            }
        }
    }

    // MARK: - 영상 재생
    func playVideo(song: UploadedSong) {
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

    // MARK: - Firestore 업로드
    func checkUserAndUpload(title: String, videoURL: URL, selectedTeam: String, completion: @escaping (Bool) -> Void) {
        if let user = Auth.auth().currentUser {
            print("로그인한 사용자: \(user.email ?? "익명")")
            uploadToFirestore(title: title, videoURL: videoURL, uploader: user.email ?? "익명", selectedTeam: selectedTeam, completion: completion)
        } else {
            print("❌ 로그인 정보가 없습니다. 다시 로그인 시도")
            Auth.auth().signInAnonymously { authResult, error in
                if let error = error {
                    print("❌ 익명 로그인 실패: \(error.localizedDescription)")
                    completion(false)
                    return
                }

                if let user = authResult?.user {
                    print("✅ 익명 로그인 성공: \(user.uid)")
                    self.uploadToFirestore(title: title, videoURL: videoURL, uploader: "익명", selectedTeam: selectedTeam, completion: completion)
                } else {
                    completion(false)
                }
            }
        }
    }

    private func uploadToFirestore(title: String, videoURL: URL, uploader: String, selectedTeam: String, completion: @escaping (Bool) -> Void) {
        let manager = UploadedSongsManager()
        manager.processAndUploadVideo(title: title, videoURL: videoURL, selectedTeam: selectedTeam, uploader: uploader) { success in
            DispatchQueue.main.async {
                if success {
                    NotificationCenter.default.post(name: NSNotification.Name("UploadSuccess"), object: nil, userInfo: ["title": title])
                    NotificationCenter.default.post(name: NSNotification.Name("RefreshUploadedSongs"), object: nil)
                }
                completion(success)
            }
        }
    }
}

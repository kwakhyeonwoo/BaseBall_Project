//
//  CheckAllVideoViewModel.swift
//     
//
//  Created by 곽현우 on 3/10/25.
//

import SwiftUI
import FirebaseFirestore

class CheckAllVideoViewModel: ObservableObject {
    @Published var uploadedSongs: [UploadedSong] = []
    @Published var likedSongs: Set<String> = [] // ✅ 사용자가 좋아요를 누른 곡 ID 저장
    @Published var likeCounts: [String: Int] = [:] // ✅ 좋아요 카운트 상태 관리

    private let db = Firestore.firestore()
    private let likedSongsKey = "likedSongs" // ✅ UserDefaults 키 값 (좋아요한 곡)
    private let likeCountsKey = "likeCounts" // ✅ UserDefaults 키 값 (좋아요 개수)

    init() {
        loadLikedSongs()  // ✅ 앱 실행 시 저장된 좋아요 상태 불러오기
        loadLikeCounts()  // ✅ 앱 실행 시 저장된 좋아요 개수 불러오기
    }

    func toggleLike(for song: UploadedSong) {
        DispatchQueue.main.async {
            if self.likedSongs.contains(song.id) {
                // ✅ 이미 좋아요를 눌렀다면 취소
                self.likedSongs.remove(song.id)
                self.likeCounts[song.id] = 0
            } else {
                // ✅ 좋아요를 누름
                self.likedSongs.insert(song.id)
                self.likeCounts[song.id] = 1
            }
            self.saveLikedSongs() // ✅ 변경 사항을 저장
            self.saveLikeCounts() // ✅ 좋아요 개수도 저장
        }
    }

    private func saveLikedSongs() {
        let likedArray = Array(likedSongs) // Set을 배열로 변환
        UserDefaults.standard.set(likedArray, forKey: likedSongsKey)
    }

    private func loadLikedSongs() {
        if let savedLikedSongs = UserDefaults.standard.array(forKey: likedSongsKey) as? [String] {
            likedSongs = Set(savedLikedSongs) // ✅ 저장된 데이터 불러와서 Set으로 변환
        }
    }

    private func saveLikeCounts() {
        UserDefaults.standard.set(likeCounts, forKey: likeCountsKey) // ✅ 딕셔너리 저장
    }

    private func loadLikeCounts() {
        if let savedLikeCounts = UserDefaults.standard.dictionary(forKey: likeCountsKey) as? [String: Int] {
            likeCounts = savedLikeCounts // ✅ 저장된 데이터 불러오기
        }
    }
}

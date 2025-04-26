//
//  MyPageViewModel.swift
//     
//
//  Created by 곽현우 on 4/10/25.
//

import Foundation
import FirebaseAuth
import FirebaseFirestore

class MyPageViewModel: ObservableObject {
    @Published var nickname: String = ""
    @Published var likedUploadedSongs: [UploadedSong] = []
    @Published var likedTeamSongs: [Song] = []
    @Published var thumbnailCache: [String: UIImage] = [:]
    
    private let db = Firestore.firestore()
    private let likedSongsKey = "likedSongs" // 공통 저장 키

    // MARK: 닉네임 불러오기
    func fetchNickname() {
        guard let user = Auth.auth().currentUser else {
            print("❌ 현재 로그인된 사용자가 없습니다.")
            return
        }

        let uid = user.uid
        db.collection("users").document(uid).getDocument { [weak self] snapshot, error in
            if let data = snapshot?.data(),
               let id = data["id"] as? String {
                DispatchQueue.main.async {
                    self?.nickname = id
                    print("✅ 닉네임: \(id)")
                }
            } else {
                print("❌ 사용자 닉네임 정보 없음")
            }
        }
    }

    // MARK: 좋아요한 팀 응원가
    func fetchLikedTeamSongs(for team: String) {
        guard let likedIDs = UserDefaults.standard.array(forKey: likedSongsKey) as? [String], !likedIDs.isEmpty else {
            print("❤️ 좋아요한 팀 응원가 없음")
            return
        }

        db.collection("songs").document(team).collection("teamSongs")
            .getDocuments { [weak self] snapshot, error in
                if let documents = snapshot?.documents {
                    let songs = documents.compactMap { doc -> Song? in
                        let data = doc.data()
                        let id = doc.documentID
                        guard likedIDs.contains(id) else { return nil }

                        return Song(
                            id: id,
                            title: data["title"] as? String ?? "제목 없음",
                            audioUrl: data["audioUrl"] as? String ?? "",
                            lyrics: data["lyrics"] as? String ?? "",
                            teamImageName: team,
                            lyricsStartTime: data["lyricsStartTime"] as? Double ?? 0,
                            timestamps: data["timestamps"] as? [Double] ?? []
                        )
                    }

                    DispatchQueue.main.async {
                        self?.likedTeamSongs = songs
                    }
                }
            }
    }

    // MARK: 업로드 한 응원가 
    func fetchLikedUploadedSongs() {
        guard let likedIds = UserDefaults.standard.array(forKey: likedSongsKey) as? [String], !likedIds.isEmpty else {
            print("💡 좋아요한 업로드 응원가 없음")
            return
        }

        db.collection("uploadedSongs")
            .whereField(FieldPath.documentID(), in: likedIds)
            .getDocuments { [weak self] snapshot, error in
                if let docs = snapshot?.documents {
                    let songs = docs.compactMap { doc -> UploadedSong? in
                        let data = doc.data()
                        return UploadedSong(
                            id: doc.documentID,
                            title: data["title"] as? String ?? "",
                            uploader: data["uploader"] as? String ?? "",
                            videoURL: data["videoURL"] as? String ?? ""
                        )
                    }
                    DispatchQueue.main.async {
                        self?.likedUploadedSongs = songs
                    }
                }
            }
    }
    
    //영상 썸네일
    func loadThumbnail(for song: UploadedSong) {
        guard let url = URL(string: song.videoURL), thumbnailCache[song.id] == nil else { return }

        generateThumbnail(from: url) { image in
            if let image = image {
                self.thumbnailCache[song.id] = image
            }
        }
    }
}

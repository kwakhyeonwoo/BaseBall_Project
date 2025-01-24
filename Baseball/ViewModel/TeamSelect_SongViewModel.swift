//
//  TeamSelect_SongViewModel.swift
//     
//
//  Created by 곽현우 on 1/21/25.
//

import FirebaseFirestore
import FirebaseStorage

class TeamSelectSongViewModel: ObservableObject {
    @Published var songs: [Song] = []
    @Published var isLoading = false

    private let db = Firestore.firestore()
    private let stoarge = Firestore.firestore()

    func fetchSongs(for team: String) {
        isLoading = true
        print("Fetching songs for team: \(team)")

        db.collection("songs").document(team).collection("teamSongs").getDocuments { [weak self] snapshot, error in
            DispatchQueue.main.async {
                self?.isLoading = false
            }

            if let error = error {
                print("Error fetching songs: \(error.localizedDescription)")
                return
            }

            guard let documents = snapshot?.documents else {
                print("No songs found for team: \(team)")
                return
            }

            print("Fetched \(documents.count) documents")

            for doc in documents {
                let data = doc.data()
                guard let title = data["title"] as? String,
                      let gsUrl = data["audioUrl"] as? String,
                      let lyrics = data["lyrics"] as? String else {
                    print("Invalid data format: \(doc.data())")
                    continue
                }

                print("Processing song: \(title), gsUrl: \(gsUrl)")

                self?.getDownloadURL(for: gsUrl) { httpUrl in
                    guard let httpUrl = httpUrl else {
                        print("Failed to convert gsUrl to HTTP URL: \(gsUrl)")
                        return
                    }

                    let song = Song(
                        id: doc.documentID,
                        title: title,
                        audioUrl: httpUrl.absoluteString,
                        lyrics: lyrics
                    )

                    DispatchQueue.main.async {
                        self?.songs.append(song)
                        print("Added song: \(song.title)")
                    }
                }
            }
        }
    }

    private func getDownloadURL(for gsUrl: String, completion: @escaping (URL?) -> Void) {
        print("Attempting to convert gsUrl: \(gsUrl)")

        // `gs://` 이후의 경로만 추출
        guard let range = gsUrl.range(of: "gs://") else {
            print("Invalid gsUrl format: \(gsUrl)")
            completion(nil)
            return
        }

        // `gs://` 이후의 경로만 추출
        let path = String(gsUrl[range.upperBound...]) // "baseball-642ed.firebasestorage.app/SSG/We are the Landers.mp4"

        // 첫 번째 '/' 이후의 경로 추출
        guard let slashIndex = path.firstIndex(of: "/") else {
            print("Invalid path format: \(path)")
            completion(nil)
            return
        }

        let storagePath = String(path[slashIndex...]).dropFirst() // "SSG/We are the Landers.mp4"
        print("Extracted storage path: \(storagePath)")

        let storageRef = Storage.storage().reference(withPath: String(storagePath))
        storageRef.downloadURL { url, error in
            if let error = error {
                print("Error fetching download URL: \(error.localizedDescription)")
                completion(nil)
            } else {
                print("Successfully fetched HTTP URL: \(url?.absoluteString ?? "nil")")
                completion(url)
            }
        }
    }
}

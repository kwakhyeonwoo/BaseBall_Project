//
//  TeamSelect_SongModel.swift
//     
//
//  Created by 곽현우 on 1/21/25.
//

import Foundation
import FirebaseFirestore
import FirebaseStorage

struct Song: Identifiable {
    let id: String
    let title: String
    let audioUrl: String
    let lyrics: String
}

class TeamSelect_SongModel {
    private let db = Firestore.firestore()

    func fetchSongs(for team: String, category: SongCategory, completion: @escaping ([Song]) -> Void) {
        print("Fetching \(category == .teamSongs ? "team songs" : "player songs") for team: \(team)")

        let collectionName = category == .teamSongs ? "teamSongs" : "playerSongs"

        db.collection("songs").document(team).collection(collectionName).getDocuments { snapshot, error in
            if let error = error {
                print("Error fetching songs: \(error.localizedDescription)")
                completion([])
                return
            }

            guard let documents = snapshot?.documents else {
                print("No songs found for \(category) in team: \(team)")
                completion([])
                return
            }

            print("Fetched \(documents.count) documents for \(category)")

            var songs: [Song] = []
            let group = DispatchGroup()

            for doc in documents {
                let data = doc.data()
                guard let title = data["title"] as? String,
                      let gsUrl = data["audioUrl"] as? String,
                      let lyrics = data["lyrics"] as? String else {
                    print("Invalid data format: \(doc.data())")
                    continue
                }

                group.enter()

                self.getDownloadURL(for: gsUrl) { httpUrl in
                    guard let httpUrl = httpUrl else {
                        print("Failed to convert gsUrl to HTTP URL: \(gsUrl)")
                        group.leave()
                        return
                    }

                    let song = Song(
                        id: doc.documentID,
                        title: title,
                        audioUrl: httpUrl.absoluteString,
                        lyrics: lyrics
                    )
                    songs.append(song)
                    group.leave()
                }
            }

            group.notify(queue: .main) {
                completion(songs)
            }
        }
    }

    private func getDownloadURL(for gsUrl: String, completion: @escaping (URL?) -> Void) {
        guard let range = gsUrl.range(of: "gs://") else {
            print("Invalid gsUrl format: \(gsUrl)")
            completion(nil)
            return
        }

        let path = String(gsUrl[range.upperBound...])
        guard let slashIndex = path.firstIndex(of: "/") else {
            print("Invalid path format: \(path)")
            completion(nil)
            return
        }

        let storagePath = String(path[slashIndex...]).dropFirst()
        print("Extracted storage path: \(storagePath)")

        let storageRef = Storage.storage().reference(withPath: String(storagePath))
        storageRef.downloadURL { url, error in
            if let error = error {
                print("Error fetching download URL: \(error.localizedDescription)")
                completion(nil)
            } else {
                completion(url)
            }
        }
    }
}

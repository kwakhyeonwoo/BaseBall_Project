//
//  TeamSelect_SongViewModel.swift
//     
//
//  Created by 곽현우 on 1/21/25.
//

import SwiftUI

enum SongCategory: String, CaseIterable {
    case teamSongs = "Team Songs"
    case playerSongs = "Player Songs"
}

class TeamSelectSongViewModel: ObservableObject {
    @Published var songs: [Song] = []
    @Published var isLoading = false
    @Published var favoriteSongs: [String] = [] // 즐겨찾기된 Song ID를 저장
    @Published var selectedCategory: SongCategory = .teamSongs // 현재 선택된 카테고리

    private let model = TeamSelect_SongModel()
    

    // MARK: - Fetch Songs
    func fetchSongs(for team: String) {
        isLoading = true
        model.fetchSongs(for: team, category: selectedCategory) { [weak self] fetchedSongs in
            DispatchQueue.main.async {
                self?.songs = fetchedSongs
                self?.isLoading = false
            }
        }
    }
    
    //곡 선택 시 gs:// -> https://로 변환
    func setupAndPlaySong(_ song: Song) {
        model.getAllSongs { [weak self] allSongs in
            DispatchQueue.main.async {
                guard let self = self else { return }
                
                if allSongs.isEmpty {
                    print("❌ Error: No songs available.")
                    return
                }

                self.songs = allSongs  // ✅ Update song list
                
                if let index = allSongs.firstIndex(where: { $0.id == song.id }) {
                    let selectedSong = allSongs[index]
                    
                    // ✅ 1️⃣ convertToHttp()로 URL 변환 시도
                    if let convertedUrlString = self.model.convertToHttp(gsUrl: selectedSong.audioUrl),
                       let url = URL(string: convertedUrlString) {
                        print("✅ [convertToHttp] 변환 성공: \(convertedUrlString)")

                        let updatedSong = Song(
                            id: selectedSong.id,
                            title: selectedSong.title,
                            audioUrl: url.absoluteString,
                            lyrics: selectedSong.lyrics,
                            teamImageName: selectedSong.teamImageName,
                            lyricsStartTime: selectedSong.lyricsStartTime,
                            timestamps: selectedSong.timestamps
                        )

                        AudioPlayerManager.shared.setPlaylist(songs: allSongs, startIndex: index)
                        AudioPlayerManager.shared.play(url: url, for: updatedSong)
                        return
                    }

                    // ✅ 2️⃣ convertToHttp() 실패 시 Firebase에서 getDownloadURL() 호출
                    self.model.getDownloadURL(for: selectedSong.audioUrl) { url in
                        DispatchQueue.main.async {
                            if let url = url {
                                print("✅ [Firebase] Retrieved URL: \(url.absoluteString)")
                                let updatedSong = Song(
                                    id: selectedSong.id,
                                    title: selectedSong.title,
                                    audioUrl: url.absoluteString,
                                    lyrics: selectedSong.lyrics,
                                    teamImageName: selectedSong.teamImageName,
                                    lyricsStartTime: selectedSong.lyricsStartTime,
                                    timestamps: selectedSong.timestamps
                                )

                                AudioPlayerManager.shared.setPlaylist(songs: allSongs, startIndex: index)
                                AudioPlayerManager.shared.play(url: url, for: updatedSong)
                            } else {
                                print("❌ Error: Failed to convert gs:// URL for \(selectedSong.title)")
                            }
                        }
                    }
                } else {
                    print("❌ Error: Selected song not found in playlist.")
                }
            }
        }
    }


    // MARK: - Toggle Favorite
    func toggleFavorite(song: Song) {
        if let index = favoriteSongs.firstIndex(of: song.id) {
            favoriteSongs.remove(at: index) // 즐겨찾기에서 제거
        } else {
            favoriteSongs.append(song.id) // 즐겨찾기에 추가
        }
    }

    // MARK: - Check if Song is Favorite
    func isFavorite(song: Song) -> Bool {
        return favoriteSongs.contains(song.id)
    }
}

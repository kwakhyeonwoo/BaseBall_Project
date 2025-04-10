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
    @Published var favoriteSongs: [String] = [] // 즐겨찾기된 Song ID 저장
    @Published var selectedCategory: SongCategory = .teamSongs

    private let model = TeamSelect_SongModel()
    private let likedSongsKey = "likedSongs" // ✅ UserDefaults 저장 키

    init() {
        loadFavoriteSongs() // ✅ 앱 실행 시 좋아요 상태 불러오기
    }

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

    // MARK: - 곡 선택 및 재생
    func setupAndPlaySong(_ song: Song) {
        model.getAllSongs { [weak self] allSongs in
            DispatchQueue.main.async {
                guard let self = self else { return }

                self.songs = allSongs

                if let index = allSongs.firstIndex(where: { $0.id == song.id }) {
                    let selectedSong = allSongs[index]

                    if let convertedUrlString = self.model.convertToHttp(gsUrl: selectedSong.audioUrl),
                       convertedUrlString.hasSuffix(".m3u8"),
                       let url = URL(string: convertedUrlString) {
                        let updatedSong = selectedSong.withUpdatedUrl(url.absoluteString)
                        AudioPlayerManager.shared.setPlaylist(songs: allSongs, startIndex: index)
                        AudioPlayerManager.shared.play(url: url, for: updatedSong)
                        return
                    }

                    self.model.getDownloadURL(for: selectedSong.audioUrl) { url in
                        DispatchQueue.main.async {
                            if let url = url, url.absoluteString.hasSuffix(".m3u8") {
                                let updatedSong = selectedSong.withUpdatedUrl(url.absoluteString)
                                AudioPlayerManager.shared.setPlaylist(songs: allSongs, startIndex: index)
                                AudioPlayerManager.shared.play(url: url, for: updatedSong)
                            } else {
                                print("❌ Error: Failed to get HLS URL")
                            }
                        }
                    }
                }
            }
        }
    }

    // MARK: - Toggle Favorite 
    func toggleFavorite(song: Song) {
        if let index = favoriteSongs.firstIndex(of: song.id) {
            favoriteSongs.remove(at: index)
        } else {
            favoriteSongs.append(song.id)
        }
        saveFavoriteSongs() // ✅ 변경사항 저장
    }

    func isFavorite(song: Song) -> Bool {
        return favoriteSongs.contains(song.id)
    }

    private func saveFavoriteSongs() {
        UserDefaults.standard.set(favoriteSongs, forKey: likedSongsKey)
    }

    private func loadFavoriteSongs() {
        if let saved = UserDefaults.standard.array(forKey: likedSongsKey) as? [String] {
            favoriteSongs = saved
        }
    }
}

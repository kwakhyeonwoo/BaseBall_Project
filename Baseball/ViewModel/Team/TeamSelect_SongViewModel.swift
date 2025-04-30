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
    @Published var favoriteSongs: [String] = []
    @Published var selectedCategory: SongCategory = .teamSongs

    private let model = TeamSelect_SongModel()
    private let likedSongsKey = "likedSongs"

    init() {
        loadFavoriteSongs()
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

    // MARK: - 재생 처리
    func setupAndPlaySong(_ song: Song) {
        guard let index = songs.firstIndex(where: { $0.id == song.id }) else {
            print("❌ Error: Song not found in current list")
            return
        }

        let selectedSong = songs[index]

        if let urlString = model.convertToHttp(gsUrl: selectedSong.audioUrl),
           urlString.hasSuffix(".m3u8"),
           let url = URL(string: urlString) {

            let updatedSong = selectedSong.withUpdatedUrl(urlString)
            AudioPlayerManager.shared.setPlaylist(songs: songs, startIndex: index)
            AudioPlayerManager.shared.play(url: url, for: updatedSong)
            return
        }

        model.getDownloadURL(for: selectedSong.audioUrl) { url in
            DispatchQueue.main.async {
                guard let url = url, url.absoluteString.hasSuffix(".m3u8") else {
                    print("❌ Error: Failed to resolve valid HLS URL")
                    return
                }
                let updatedSong = selectedSong.withUpdatedUrl(url.absoluteString)
                AudioPlayerManager.shared.setPlaylist(songs: self.songs, startIndex: index)
                AudioPlayerManager.shared.play(url: url, for: updatedSong)
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
        saveFavoriteSongs()
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

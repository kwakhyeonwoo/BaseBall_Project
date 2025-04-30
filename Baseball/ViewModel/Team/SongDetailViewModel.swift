//
//  SongDetailViewModel.swift
//     
//
//  Created by 곽현우 on 2/12/25.
//

import SwiftUI
import Combine
import AVFoundation

class SongDetailViewModel: ObservableObject {
    @Published var isPlaying: Bool = false
    @Published var duration: Double = 0
    @Published var currentTime: Double = 0
    @Published var progress: Double = 0
    @Published var didFinishPlaying: Bool = false
    @Published var hasPrevSong: Bool = false
    @Published var hasNextSong: Bool = false
    @Published var currentSong: Song?
    @Published var lyricsStartTime: Double = 0.0
    @Published var timestamps: [Double] = []

    private let playerManager = AudioPlayerManager.shared
    private let songModel = TeamSelect_SongModel()
    private var cancellables = Set<AnyCancellable>()

    init() {
        setupBindings()
    }

    private func setupBindings() {
        playerManager.$isPlaying.receive(on: RunLoop.main).assign(to: &$isPlaying)
        playerManager.$currentTime.receive(on: RunLoop.main).sink { [weak self] time in
            guard let self = self else { return }
            self.currentTime = time
            let safeDuration = max(1, self.playerManager.duration)
            self.progress = min(1, max(0, time / safeDuration))
        }.store(in: &cancellables)
        playerManager.$duration.receive(on: RunLoop.main).assign(to: &$duration)
        playerManager.$didFinishPlaying.receive(on: RunLoop.main).assign(to: &$didFinishPlaying)
        playerManager.$currentSong.receive(on: RunLoop.main).sink { [weak self] newSong in
            self?.updateCurrentSong(newSong)
        }.store(in: &cancellables)
    }

    private func updateCurrentSong(_ newSong: Song?) {
        guard let song = newSong else { return }
        currentSong = song
        lyricsStartTime = song.lyricsStartTime
        timestamps = song.timestamps
        checkPreviousSongAvailability(for: song)
        checkNextSongAvailability(for: song)
    }

    func setupPlayerIfNeeded(for song: Song) {
        songModel.getDownloadURL(for: song.audioUrl) { [weak self] url in
            guard let self = self, let url = url else {
                print("❌ URL 변환 실패: \(song.audioUrl)")
                return
            }
            if self.playerManager.getCurrentUrl() == url {
                return
            }
            self.playerManager.play(url: url, for: song)
            DispatchQueue.main.async {
                self.playerManager.backgroundManager.updateNowPlayingInfo()
            }
        }
    }

    func togglePlayPause(for song: Song) {
        guard let url = URL(string: song.audioUrl) else { return }
        if playerManager.isPlaying {
            playerManager.pause()
        } else {
            if playerManager.currentUrl == url {
                playerManager.resume()
            } else {
                playerManager.play(url: url, for: song)
            }
        }
    }

    func playPrevious() {
        playerManager.playPrevious()
    }

    func playNext() {
        playerManager.playNext()
    }

    func checkPreviousSongAvailability(for song: Song) {
        playerManager.hasPreviousSong(for: song) { [weak self] hasPrevious in
            DispatchQueue.main.async {
                self?.hasPrevSong = hasPrevious
            }
        }
    }

    func checkNextSongAvailability(for song: Song) {
        playerManager.hasNextSong(for: song) { [weak self] hasNext in
            DispatchQueue.main.async {
                self?.hasNextSong = hasNext
            }
        }
    }

    func seek(to time: Double) {
        playerManager.seek(to: time)
    }

    func resetFinishState() {
        playerManager.didFinishPlaying = false
    }
}

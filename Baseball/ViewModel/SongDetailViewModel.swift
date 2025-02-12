//
//  SongDetailViewModel.swift
//     
//
//  Created by 곽현우 on 2/12/25.
//

import SwiftUI
import Combine

class SongDetailViewModel: ObservableObject {
    @Published var isPlaying: Bool = false
    @Published var duration: Double = 0
    @Published var currentTime: Double = 0
    @Published var progress: Double = 0
    @Published var didFinishPlaying: Bool = false

    private let playerManager = AudioPlayerManager.shared
    private var cancellables = Set<AnyCancellable>()

    init() {
        playerManager.$isPlaying
            .receive(on: RunLoop.main)
            .assign(to: &$isPlaying)
        
        playerManager.$currentTime
            .receive(on: RunLoop.main)
            .sink { [weak self] time in
                guard let self = self else {return}
                self.currentTime = time
                let safeDuration = max(1, self.playerManager.duration)
                self.progress = min(1, max(0, time / safeDuration))
            }
            .store(in: &cancellables)
        
        playerManager.$duration
            .receive(on: RunLoop.main)
            .assign(to: &$duration)
        
        playerManager.$didFinishPlaying
            .receive(on: RunLoop.main)
            .assign(to: &$didFinishPlaying)
    }
    
    func setupPlayerIfNeeded(for song: Song) {
        guard playerManager.getCurrentUrl() != URL(string: song.audioUrl) else { return }
        guard let url = URL(string: song.audioUrl) else { return }
        playerManager.play(url: url, for: song)
    }

    func togglePlayPause(for song: Song) {
        if playerManager.isPlaying {
            playerManager.pause()
        } else {
            if let currentUrl = playerManager.getCurrentUrl(), currentUrl == URL(string: song.audioUrl) {
                playerManager.resume()
            } else {
                playerManager.play(url: URL(string: song.audioUrl)!, for: song)
            }
        }
    }

    func playPrevious() {
        playerManager.playPrevious()
    }

    func playNext() {
        playerManager.playNext()
    }

    func hasPreviousSong() -> Bool {
        return playerManager.hasPreviousSong()
    }

    func hasNextSong() -> Bool {
        return playerManager.hasNextSong()
    }

    func seek(to time: Double) {
        playerManager.seek(to: time)
    }

    func resetFinishState() {
        playerManager.didFinishPlaying = false
    }
}

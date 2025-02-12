//
//  AudioPlayerManager.swift
//     
//
//  Created by 곽현우 on 1/31/25.
//

import AVFoundation
import Combine
import MediaPlayer

class AudioPlayerManager: ObservableObject {
    static let shared = AudioPlayerManager()

    @Published var isPlaying: Bool = false
    @Published var currentTime: Double = 0
    @Published var duration: Double = 0
    @Published var didFinishPlaying: Bool = false
    @Published private var currentIndex: Int? = nil

    private var player: AVPlayer?
    private var playerObserver: Any?
    private var currentUrl: URL?
    private(set) var currentSong: Song?
    private let backgroundManager = AVPlayerBackgroundManager()
    private var playlist: [Song] = []

    init() {
        backgroundManager.setupAudioSessionNotifications()
        backgroundManager.configureRemoteCommandCenter(for: self)
        setupEndTimeObserver()
    }
    
    var progress: Double {
        get {
            duration > 0 ? currentTime / duration : 0
        }
        set {
            seek(to: newValue * duration)
        }
    }
    
    // MARK: - 재생 메서드
    func play(url: URL, for song: Song) {
        if currentUrl != url {
            setupPlayer(url: url, for: song)
            currentUrl = url
            currentSong = song
            currentIndex = playlist.firstIndex(where: { $0.id == song.id })
        }

        player?.play()
        isPlaying = true
        backgroundManager.setupNowPlayingInfo(for: song, player: player)
    }

    // MARK: - 플레이어 초기화
    private func setupPlayer(url: URL, for song: Song) {
        stop()
        let playerItem = AVPlayerItem(url: url)
        player = AVPlayer(playerItem: playerItem)
        
        playerItem.preferredForwardBufferDuration = 5
        
        playerItem.asset.loadValuesAsynchronously(forKeys: ["duration"]) {
            DispatchQueue.main.async {
                self.duration = CMTimeGetSeconds(playerItem.asset.duration)
                self.backgroundManager.setupNowPlayingInfo(for: song, player: self.player)
            }
        }
        NotificationCenter.default.addObserver(self, selector: #selector(handlePlaybackEnded), name: .AVPlayerItemDidPlayToEndTime, object: playerItem)

        playerObserver = player?.addPeriodicTimeObserver(forInterval: CMTime(seconds: 0.1, preferredTimescale: 600), queue: .main) { time in
            self.currentTime = CMTimeGetSeconds(time)
            self.backgroundManager.updateNowPlayingPlaybackState(for: self.player, duration: self.duration)
        }
    }

    // MARK: - 재생목록 설정
    func setPlaylist(songs: [Song], startIndex: Int) {
        playlist = songs
        currentIndex = startIndex
        if let song = playlist[safe: startIndex] {
            play(url: URL(string: song.audioUrl)!, for: song)
        }
    }

    // MARK: - 이전 / 다음 곡 재생
    func playPrevious() {
        guard let currentIndex = currentIndex, currentIndex > 0 else {
            print("⚠️ No previous song available.")
            return
        }
        let previousIndex = currentIndex - 1
        self.currentIndex = previousIndex // ✅ 현재 인덱스 업데이트

        if let previousSong = playlist[safe: previousIndex] {
            play(url: URL(string: previousSong.audioUrl)!, for: previousSong)
        }
    }

    func playNext() {
        guard let currentIndex = currentIndex, currentIndex < playlist.count - 1 else {
            print("⚠️ No next song available.")
            return
        }
        let nextIndex = currentIndex + 1
        self.currentIndex = nextIndex // ✅ 현재 인덱스 업데이트

        if let nextSong = playlist[safe: nextIndex] {
            play(url: URL(string: nextSong.audioUrl)!, for: nextSong)
        }
    }


    // MARK: - 이전/다음 곡이 있는지 확인
    func hasPreviousSong() -> Bool {
        guard let currentIndex = currentIndex, !playlist.isEmpty else { return false }
        return currentIndex > 0
    }

    func hasNextSong() -> Bool {
        guard let currentIndex = currentIndex, !playlist.isEmpty else { return false }
        return currentIndex < playlist.count - 1
    }

    
    // MARK: - 일시정지
    func pause() {
        player?.pause()
        isPlaying = false
        backgroundManager.updateNowPlayingPlaybackState(for: player, duration: duration)
    }
    
    // MARK: - 다시 시작
    func resume() {
        player?.play()
        isPlaying = true
    }

    // MARK: - 음원 종료시 메모리 해제
    func stop() {
        player?.pause()
        player = nil
        currentUrl = nil
        currentTime = 0
        duration = 0
        isPlaying = false
        
        if let observer = playerObserver {
            player?.removeTimeObserver(observer)
            playerObserver = nil
        }
    }

    // MARK: - 실행되고 있는 URL 불러오기
    func getCurrentUrl() -> URL? {
        return currentUrl
    }
    
    // MARK: - 동영상 막대바 이동
    func seek(to time: Double) {
        guard let player = player else { return }
        let newTime = CMTime(seconds: time, preferredTimescale: 600)
        player.seek(to: newTime)
        currentTime = time
    }
    
    // 종료 알림 설정
    private func setupEndTimeObserver() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(playerDidFinishPlaying),
            name: .AVPlayerItemDidPlayToEndTime,
            object: nil
        )
    }
    
    // 재생이 끝났을 때 호출되는 메서드
    @objc private func playerDidFinishPlaying() {
        playNext()
    }
    
    @objc private func handlePlaybackEnded(){
        DispatchQueue.main.async{
            self.didFinishPlaying = true
            self.stop()
        }
    }
}

// 배열 범위 체크를 안전하게 하기 위한 확장 기능
extension Array {
    subscript(safe index: Int) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}

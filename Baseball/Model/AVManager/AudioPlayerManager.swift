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
    private let firestoreService = TeamSelect_SongModel()

    @Published var isPlaying: Bool = false
    @Published var currentTime: Double = 0
    @Published var duration: Double = 0
    @Published var didFinishPlaying: Bool = false
    @Published private var currentIndex: Int? = nil
    @Published var currentSong: Song?

    var player: AVPlayer?
    private var playerObserver: Any?
    private var currentUrl: URL?
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
    func play(url: URL?, for song: Song) {
        guard let url = url else {
            print("❌ Error: URL is nil for song \(song.title)")
            return
        }

        stop()  // ✅ Stop any current playback
        setupPlayer(url: url, for: song)
        currentUrl = url  // ✅ 새로운 URL 업데이트
        currentSong = song

        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }

            // ✅ Make sure currentSong is set before playing
            self.currentSong = song

            self.player?.play()
            self.isPlaying = true
            self.backgroundManager.setupNowPlayingInfo(for: song, player: self.player)
            print("🎵 Now Playing: \(song.title), URL: \(url)")
        }
    }



    // MARK: - 플레이어 초기화
    private func setupPlayer(url: URL, for song: Song) {
        stop()  // ✅ 기존 플레이어 정리

        let playerItem = AVPlayerItem(url: url)
        player = AVPlayer(playerItem: playerItem)

        playerItem.preferredForwardBufferDuration = 5

        playerItem.asset.loadValuesAsynchronously(forKeys: ["duration"]) {
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                
                if self.player?.currentItem !== playerItem {
                    print("⚠️ AVPlayerItem 교체 확인 실패")
                    return
                }

                self.duration = CMTimeGetSeconds(playerItem.duration)
                self.backgroundManager.setupNowPlayingInfo(for: song, player: self.player)

                print("✅ 새로운 곡 로드 완료: \(song.title)")
            }
        }

        NotificationCenter.default.addObserver(self, selector: #selector(handlePlaybackEnded), name: .AVPlayerItemDidPlayToEndTime, object: playerItem)

        playerObserver = player?.addPeriodicTimeObserver(forInterval: CMTime(seconds: 0.1, preferredTimescale: 600), queue: .main) { time in
            DispatchQueue.main.async {
                self.currentTime = CMTimeGetSeconds(time)
                self.backgroundManager.updateNowPlayingPlaybackState(for: self.player, duration: self.duration)
            }
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
        guard let currentSong = currentSong else {
            print("⚠️ No currently playing song.")
            return
        }

        firestoreService.getPreviousSong(for: currentSong) { [weak self] previousSong in
            guard let self = self, let previousSong = previousSong else {
                print("⚠️ No previous song found.")
                return
            }
            //getDownloadURL에서 gs -> https로 변경하기
            self.firestoreService.getDownloadURL(for: previousSong.audioUrl) { url in
                DispatchQueue.main.async {
                    if let url = url {
                        self.currentSong = previousSong
                        self.currentUrl = URL(string: previousSong.audioUrl)
                        self.play(url: url, for: previousSong) // ✅ Play the converted URL
                    } else {
                        print("❌ Error: Failed to convert gs:// URL for \(previousSong.title)")
                    }
                }
            }
        }
    }

    func playNext() {
        guard let currentSong = currentSong else {
            print("⚠️ No currently playing song.")
            return
        }

        firestoreService.getNextSong(for: currentSong) { [weak self] nextSong in
            guard let self = self, let nextSong = nextSong else {
                print("⚠️ No next song found.")
                return
            }

            self.firestoreService.getDownloadURL(for: nextSong.audioUrl) { url in
                DispatchQueue.main.async {
                    if let url = url {
                        self.currentSong = nextSong
                        self.currentUrl = URL(string: nextSong.audioUrl)
                        self.play(url: url, for: nextSong) // ✅ Play the converted URL
                    } else {
                        print("❌ Error: Failed to convert gs:// URL for \(nextSong.title)")
                    }
                }
            }
        }
    }

    // 🔹 Firestore 기반 이전 곡 여부 확인
    func hasPreviousSong(for song: Song, completion: @escaping (Bool) -> Void) {
        firestoreService.hasPreviousSong(for: song) { hasPrevious in
            completion(hasPrevious)
        }
    }

    // 🔹 Firestore 기반 다음 곡 여부 확인
    // completion에서 false발생
    func hasNextSong(for song: Song, completion: @escaping (Bool) -> Void) {
        firestoreService.getAllSongs { songs in
            guard let index = songs.firstIndex(where: { $0.id == song.id }) else {
                print("⚠️ Current song not found in playlist: \(song.title)")
                completion(false)
                return
            }

            let hasNext = index < songs.count - 1
            print("🔍 Checking next song availability for \(song.title) at index \(index). Has Next: \(hasNext)")
            completion(hasNext)
        }
    }

    // MARK: - 일시정지
    func pause() {
        guard let player = player else {
            print("❌ Error: Player is nil, cannot pause playback.")
            return
        }
        
        print("⏸️ Pausing playback...")
        
        player.pause()
        isPlaying = false
        backgroundManager.updateNowPlayingPlaybackState(for: player, duration: duration)
    }
    
    // MARK: - 다시 시작
    func resume() {
        guard let player = player else {
            print("❌ Error: Player is nil. Cannot resume playback.")
            return
        }

        if let currentUrl = currentUrl, let currentSong = currentSong {
            print("▶️ Resuming playback of: \(currentSong.title), URL: \(currentUrl)")

            if player.currentItem == nil {
                print("⚠️ AVPlayerItem is nil, reloading song...")
                play(url: currentUrl, for: currentSong) // Reload and play
            } else {
                player.play()
                isPlaying = true
                backgroundManager.setupNowPlayingInfo(for: currentSong, player: player)
            }
        } else {
            print("❌ Error: currentUrl or currentSong is nil, cannot resume playback.")
        }
    }

    // MARK: - 음원 종료시 메모리 해제
    func stop() {
        player?.pause()
        // ✅ 현재 재생 중인 AVPlayerItem을 완전히 해제
        player?.replaceCurrentItem(with: nil)
        
        player = nil
//        currentUrl = nil  // ✅ 기존 URL 완전히 초기화
        currentTime = 0
        duration = 0
        isPlaying = false
        
        // ✅ 기존 timeObserver 제거 (안 그러면 메모리 누수 가능성 있음)
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
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.backgroundManager.setupNowPlayingInfo(for: self.currentSong!, player: self.player)
        }
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

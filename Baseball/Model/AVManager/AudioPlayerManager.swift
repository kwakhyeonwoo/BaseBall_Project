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
    var currentUrl: URL?
    private var playerObserver: Any?
    let backgroundManager = AVPlayerBackgroundManager()
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
        currentUrl = url
        currentSong = song

        // ✅ Save the correct song and time BEFORE playback starts
        saveCurrentSong(song, time: 0)

        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }

            self.currentSong = song
            self.player?.play()
            self.isPlaying = true

            // ✅ Update Control Center NOW (before background mode)
            self.backgroundManager.setupNowPlayingInfo(for: song, player: self.player)
            print("🎵 Now Playing: \(song.title), URL: \(url)")
        }
    }



    // MARK: - 플레이어 초기화 -> 초기화해서 불러올때 gs://로 불러옴.
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

        if let observer = playerObserver {
            player?.removeTimeObserver(observer)
            playerObserver = nil
        }

        let savedTime = self.currentTime

        playerObserver = player?.addPeriodicTimeObserver(forInterval: CMTime(seconds: 0.1, preferredTimescale: 600), queue: .main) { time in
            DispatchQueue.main.async {
                self.currentTime = CMTimeGetSeconds(time)
                self.backgroundManager.updateNowPlayingPlaybackState(for: self.player, duration: self.duration)
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.player?.seek(to: CMTime(seconds: savedTime, preferredTimescale: 600))
            self.player?.play()
            self.isPlaying = true
            self.backgroundManager.setupNowPlayingInfo(for: song, player: self.player)
        }

        NotificationCenter.default.addObserver(self, selector: #selector(handlePlaybackEnded), name: .AVPlayerItemDidPlayToEndTime, object: playerItem)
    }

    // MARK: - 재생목록 설정
    func setPlaylist(songs: [Song], startIndex: Int) {
        playlist = songs
        currentIndex = startIndex
        guard let song = playlist[safe: startIndex] else {
            print("❌ Error: Invalid start index for playlist.")
            return
        }
        if let url = URL(string: song.audioUrl) {
            play(url: url, for: song)
        } else {
            print("❌ Error: Invalid URL for song \(song.title)")
        }

    }

    // MARK: - 이전 / 다음 곡 재생
    func playPrevious() {
        guard let currentSong = currentSong else {
            print("⚠️ No currently playing song.")
            return
        }

        firestoreService.getPreviousSong(for: currentSong) { [weak self] previousSong in
            guard let self = self else { return }

            if let previousSong = previousSong {
                print("✅ Previous song found: \(previousSong.title)")

                self.firestoreService.getDownloadURL(for: previousSong.audioUrl) { url in
                    DispatchQueue.main.async {
                        if let url = url {
                            print("🔗 Converted URL for previous song: \(url.absoluteString)")

                            // ✅ 최신 곡으로 업데이트
                            self.currentSong = Song(
                                id: previousSong.id,
                                title: previousSong.title,
                                audioUrl: url.absoluteString,
                                lyrics: previousSong.lyrics,
                                teamImageName: previousSong.teamImageName
                            )

                            self.currentUrl = url
                                self.currentSong = self.currentSong  // ✅ playerManager에 반영
                            self.currentUrl = self.currentUrl  // ✅ 최신 URL 저장

                            self.play(url: url, for: self.currentSong!)
                        } else {
                            print("❌ Error: Failed to convert gs:// URL for previous song")
                        }
                    }
                }
            } else {
                print("⚠️ No previous song available.")
            }
        }
    }

    func playNext() {
        guard let currentSong = self.currentSong else { return }

        firestoreService.getNextSong(for: currentSong) { [weak self] nextSong in
            guard let self = self else { return }

            if let nextSong = nextSong {
                self.firestoreService.getDownloadURL(for: nextSong.audioUrl) { url in
                    DispatchQueue.main.async {
                        if let url = url {
                            print("🔗 다음 곡 URL 변환 완료: \(url.absoluteString)")

                            let updatedNextSong = Song(
                                id: nextSong.id,
                                title: nextSong.title,
                                audioUrl: url.absoluteString,
                                lyrics: nextSong.lyrics,
                                teamImageName: nextSong.teamImageName
                            )

                            self.currentSong = updatedNextSong
                            self.currentUrl = url
                            self.objectWillChange.send()

                            self.play(url: url, for: updatedNextSong)

                            // ✅ Immediately update Control Center with new song
                            self.backgroundManager.setupNowPlayingInfo(for: updatedNextSong, player: self.player)
                            self.backgroundManager.updateNowPlayingPlaybackState(for: self.player, duration: self.duration)
                        } else {
                            print("❌ Error: Failed to convert gs:// URL for next song")
                        }
                    }
                }
            } else {
                print("⚠️ No next song available.")
            }
        }
    }

    func saveCurrentSong(_ song: Song, time: Double) {
        if let encodedSong = try? JSONEncoder().encode(song) {
            UserDefaults.standard.set(encodedSong, forKey: "currentSong")
        }
        UserDefaults.standard.set(time, forKey: "currentTime")
        UserDefaults.standard.synchronize() // ✅ Ensure data is written immediately
    }

    // 🔹 Firestore 기반 이전 곡 여부 확인
    func hasNextSong(for song: Song, completion: @escaping (Bool) -> Void) {
        firestoreService.getAllSongs { songs in
            guard let index = songs.firstIndex(where: { $0.id == song.id }) else {
                completion(false) // ✅ Song not found, return false
                return
            }
            completion(songs.indices.contains(index + 1)) // ✅ Check if next song exists
        }
    }

    func hasPreviousSong(for song: Song, completion: @escaping (Bool) -> Void) {
        firestoreService.getAllSongs { songs in
            guard let index = songs.firstIndex(where: { $0.id == song.id }) else {
                completion(false) // ✅ Song not found, return false
                return
            }
            completion(songs.indices.contains(index - 1)) // ✅ Check if previous song exists
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
            // ✅ Load saved song and time correctly
            if let savedData = UserDefaults.standard.data(forKey: "currentSong"),
               let savedSong = try? JSONDecoder().decode(Song.self, from: savedData),
               let savedTime = UserDefaults.standard.value(forKey: "currentTime") as? Double {

                print("🔄 Restoring song from background: \(savedSong.title)")
                play(url: URL(string: savedSong.audioUrl), for: savedSong)
                seek(to: savedTime)  // ✅ Ensure it starts from the correct position

                // ✅ Force update background metadata
                self.backgroundManager.updateNowPlayingInfo()

                return
            }

            print("❌ Error: Player is nil. Cannot resume playback.")
            return
        }

        player.play()
        isPlaying = true
        backgroundManager.updateNowPlayingInfo()
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
    
    // MARK: - 동영상 막대바 이동 - 언래핑
    func seek(to time: Double) {
        guard let player = player else { return }
        let newTime = CMTime(seconds: time, preferredTimescale: 600)
        player.seek(to: newTime)
        currentTime = time
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            guard let currentSong = self.currentSong else {
                print("❌ Error: No current song found while seeking")
                return
            }
            self.backgroundManager.setupNowPlayingInfo(for: currentSong, player: self.player)
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

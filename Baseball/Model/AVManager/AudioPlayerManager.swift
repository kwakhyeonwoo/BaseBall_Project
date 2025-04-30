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
    @Published private(set) var currentIndex: Int? = nil
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
        get { duration > 0 ? currentTime / duration : 0 }
        set { seek(to: newValue * duration) }
    }

    // MARK: - 플레이어 초기화 및 재생
    func play(url: URL?, for song: Song) {
        guard let url = url else {
            print("❌ URL is nil for song \(song.title)")
            return
        }
        let urlString = url.absoluteString
        guard let encodedUrl = urlString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let encodedURL = URL(string: encodedUrl) else {
            print("❌ 유효하지 않은 HLS URL: \(urlString)")
            return
        }
        
        print("📥 입력받은 .m3u8 URL: \(url.absoluteString)")
        stop()
        
        downloadAndPrepareM3U8(from: url) { [weak self] preparedURL in
            guard let self = self, let preparedURL = preparedURL else {
                print("❌ M3U8 처리 실패")
                return
            }
            
            print("🎬 AVPlayer에 사용할 최종 URL: \(preparedURL)")
            
            let item = AVPlayerItem(url: preparedURL)
            self.player = AVPlayer(playerItem: item)
            self.currentUrl = preparedURL
            self.currentSong = song
            
            item.asset.loadValuesAsynchronously(forKeys: ["duration"]) {
                DispatchQueue.main.async {
                    self.duration = CMTimeGetSeconds(item.asset.duration)
                    self.backgroundManager.setupNowPlayingInfo(for: song, player: self.player)
                }
            }
            
            self.playerObserver = self.player?.addPeriodicTimeObserver(
                forInterval: CMTime(seconds: 0.1, preferredTimescale: 600),
                queue: .main
            ) { [weak self] time in
                guard let self = self else { return }
                self.currentTime = CMTimeGetSeconds(time)
                self.backgroundManager.updateNowPlayingPlaybackState(for: self.player, duration: self.duration)
            }
            
            self.player?.play()
            self.isPlaying = true
            self.backgroundManager.setupNowPlayingInfo(for: song, player: self.player)
            
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(self.handlePlaybackEnded),
                name: .AVPlayerItemDidPlayToEndTime,
                object: item
            )
        }
    }
    
    // MARK: - m3u8 파일 절대경로로 전환
    private func downloadAndPrepareM3U8(from url: URL, completion: @escaping (URL?) -> Void) {
        let session = URLSession.shared
        session.dataTask(with: url) { data, response, error in
            guard let data = data, let content = String(data: data, encoding: .utf8) else {
                print("❌ .m3u8 다운로드 실패: \(error?.localizedDescription ?? "알 수 없음")")
                DispatchQueue.main.async { completion(nil) }
                return
            }
            
            let lines = content.split(separator: "\n")
            let folderURL = url.deletingLastPathComponent()
            
            let modifiedContent = lines.map { line -> String in
                if line.hasSuffix(".ts") {
                    let tsFile = String(line)
                    let absolute = folderURL.appendingPathComponent(tsFile).absoluteString
                    print("🔄 상대경로 → 절대경로 변환: \(tsFile) → \(absolute)")
                    return absolute
                }
                return String(line)
            }.joined(separator: "\n")
            
            let tempFile = FileManager.default.temporaryDirectory
                .appendingPathComponent(UUID().uuidString + ".m3u8")
            
            do {
                try modifiedContent.write(to: tempFile, atomically: true, encoding: .utf8)
                print("✅ 수정된 .m3u8 로컬 저장 완료: \(tempFile)")
                DispatchQueue.main.async { completion(tempFile) }
            } catch {
                print("❌ .m3u8 저장 실패: \(error.localizedDescription)")
                DispatchQueue.main.async { completion(nil) }
            }
        }.resume()
    }
    
    // MARK: - 일시정지
    func pause() {
        player?.pause()
        isPlaying = false
        backgroundManager.updateNowPlayingPlaybackState(for: player, duration: duration)
    }

    // MARK: - 다시시작
    func resume() {
        if let savedData = UserDefaults.standard.data(forKey: "currentSong"),
           let savedSong = try? JSONDecoder().decode(Song.self, from: savedData),
           let savedTime = UserDefaults.standard.value(forKey: "currentTime") as? Double {
            play(url: URL(string: savedSong.audioUrl), for: savedSong)
            seek(to: savedTime)
            backgroundManager.updateNowPlayingInfo()
        } else {
            print("❌ No saved song to resume")
        }
    }

    // MARK: - 멈춤
    func stop() {
        player?.pause()
        player?.replaceCurrentItem(with: nil)
        player = nil
        currentTime = 0
        duration = 0
        isPlaying = false
        if let observer = playerObserver {
            player?.removeTimeObserver(observer)
            playerObserver = nil
        }
    }

    // MARK: - 막대바 이동
    func seek(to time: Double) {
        guard let player = player else { return }
        player.seek(to: CMTime(seconds: time, preferredTimescale: 600))
        currentTime = time
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            if let currentSong = self.currentSong {
                self.backgroundManager.setupNowPlayingInfo(for: currentSong, player: self.player)
            }
        }
    }

    // MARK: - 다음 / 이전 곡
    func hasNextSong(for song: Song, completion: @escaping (Bool) -> Void) {
        firestoreService.getAllSongs { songs in
            guard let index = songs.firstIndex(where: { $0.id == song.id }) else {
                completion(false)
                return
            }
            completion(songs.indices.contains(index + 1))
        }
    }

    func hasPreviousSong(for song: Song, completion: @escaping (Bool) -> Void) {
        firestoreService.getAllSongs { songs in
            guard let index = songs.firstIndex(where: { $0.id == song.id }) else {
                completion(false)
                return
            }
            completion(songs.indices.contains(index - 1))
        }
    }

    @objc private func handlePlaybackEnded() {
        didFinishPlaying = true
        stop()
    }

    @objc private func playerDidFinishPlaying() {
        playNext()
    }

    private func setupEndTimeObserver() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(playerDidFinishPlaying),
            name: .AVPlayerItemDidPlayToEndTime,
            object: nil
        )
    }

    // MARK: - 현재 재생 URL
    func getCurrentUrl() -> URL? {
        return currentUrl
    }

    // MARK: - 플레이리스트 처리
    func setPlaylist(songs: [Song], startIndex: Int) {
        playlist = songs
        currentIndex = startIndex
        if let song = playlist[safe: startIndex], let url = URL(string: song.audioUrl) {
            play(url: url, for: song)
        }
    }

    func playNext() {
        guard let currentSong = currentSong else { return }
        firestoreService.getNextSong(for: currentSong) { [weak self] next in
            guard let self = self, let next = next, let url = URL(string: next.audioUrl) else { return }
            if let idx = self.playlist.firstIndex(where: { $0.id == next.id }) {
                self.currentIndex = idx
            }
            self.play(url: url, for: next)
        }
    }

    func playPrevious() {
        guard let currentSong = currentSong else { return }
        firestoreService.getPreviousSong(for: currentSong) { [weak self] prev in
            guard let self = self, let prev = prev, let url = URL(string: prev.audioUrl) else { return }
            if let idx = self.playlist.firstIndex(where: { $0.id == prev.id }) {
                self.currentIndex = idx
            }
            self.play(url: url, for: prev)
        }
    }
}

extension Array {
    subscript(safe index: Int) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}

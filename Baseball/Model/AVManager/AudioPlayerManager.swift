//
//  AudioPlayerManager.swift
//     
//
//  Created by 곽현우 on 1/31/25.
//

import AVFoundation
import Combine

class AudioPlayerManager: ObservableObject {
    static let shared = AudioPlayerManager()

    @Published var isPlaying: Bool = false
    @Published var currentTime: Double = 0
    @Published var duration: Double = 0

    private var player: AVPlayer?
    private var playerObserver: Any?
    private var currentUrl: URL?

    // URL을 통해 재생
    func play(url: URL) {
        if currentUrl != url {
            // 새로운 URL인 경우에만 플레이어 초기화
            setupPlayer(url: url)
            currentUrl = url
        }

        player?.play()
        isPlaying = true
    }

    // 플레이어 초기화
    private func setupPlayer(url: URL) {
        stop()  // 기존 플레이어 정리

        let playerItem = AVPlayerItem(url: url)
        player = AVPlayer(playerItem: playerItem)

        // 총 재생 시간 가져오기
        playerItem.asset.loadValuesAsynchronously(forKeys: ["duration"]) {
            DispatchQueue.main.async {
                self.duration = CMTimeGetSeconds(playerItem.asset.duration)
            }
        }

        // 시간 업데이트 옵저버 추가
        playerObserver = player?.addPeriodicTimeObserver(forInterval: CMTime(seconds: 1, preferredTimescale: 1), queue: .main) { time in
            self.currentTime = CMTimeGetSeconds(time)
        }
    }

    // 일시 정지
    func pause() {
        player?.pause()
        isPlaying = false
    }

    // 현재 URL 반환
    func getCurrentUrl() -> URL? {
        return currentUrl
    }

    // 정지 및 메모리 해제, 메모리 관리
    func stop() {
        player?.pause()
        player = nil
        currentUrl = nil
        currentTime = 0
        duration = 0
        isPlaying = false

        // 옵저버 해제
        if let observer = playerObserver {
            player?.removeTimeObserver(observer)
            playerObserver = nil
        }
    }
}

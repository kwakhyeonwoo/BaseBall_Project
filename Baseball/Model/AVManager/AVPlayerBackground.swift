//
//  AVPlayerBackground.swift
//
//
//  Created by 곽현우 on 2/4/25.
//

import AVFoundation
import MediaPlayer

class AVPlayerBackgroundManager {
    
    // MARK: - 오디오 세션 설정 및 알림
    // 오디오 인터럽션 감지.
    func setupAudioSessionNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleInterruption),
            name: AVAudioSession.interruptionNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleRouteChange),
            name: AVAudioSession.routeChangeNotification,
            object: nil
        )
    }
    func setupBackgroundPlaybackNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAppDidEnterBackground),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAppWillEnterForeground),
            name: UIApplication.willEnterForegroundNotification,
            object: nil
        )
    }

    /// ✅ **오디오 세션 설정** (백그라운드에서도 재생 유지)
    static func configureAudioSession() {
        let audioSession = AVAudioSession.sharedInstance()

        do {
            // ✅ 올바른 옵션을 설정하여 중복 호출 방지
            try audioSession.setCategory(.playback, mode: .default, options: [.allowAirPlay, .allowBluetooth, .allowBluetoothA2DP])

            // ✅ 세션을 활성화 (에러 발생 방지)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
            
            print("✅ Audio session configured successfully for background playback.")
        } catch let error {
            print("❌ Audio session 설정 실패: \(error.localizedDescription)")
        }
    }


    // MARK: - 제어센터 명령 설정
    func configureRemoteCommandCenter(for playerManager: AudioPlayerManager) {
        let commandCenter = MPRemoteCommandCenter.shared()

        //재생
        commandCenter.playCommand.addTarget { [weak playerManager] _ in
            guard let playerManager = playerManager,
                  let currentUrl = playerManager.getCurrentUrl(),
                  let currentSong = playerManager.currentSong else { return .commandFailed }

            if !playerManager.isPlaying {
                playerManager.play(url: currentUrl, for: currentSong)
            }
            return .success
        }

        //일시정지
        commandCenter.pauseCommand.addTarget { [weak playerManager] _ in
            playerManager?.pause()
            return .success
        }

        //재생, 일시정지 토글
        commandCenter.togglePlayPauseCommand.addTarget { [weak playerManager] _ in
            guard let playerManager = playerManager,
                  let currentUrl = playerManager.getCurrentUrl(),
                  let currentSong = playerManager.currentSong else { return .commandFailed }

            if playerManager.isPlaying {
                playerManager.pause()
            } else {
                playerManager.play(url: currentUrl, for: currentSong)
            }
            return .success
        }
        
        //이전 음원
        commandCenter.previousTrackCommand.addTarget { [weak playerManager] _ in
                guard let playerManager = playerManager else { return .commandFailed }
                
                if let currentSong = playerManager.currentSong {
                    playerManager.playPrevious()
                    return .success
                }
                return .commandFailed
            }
        
        //다음 음원
        commandCenter.nextTrackCommand.addTarget { [weak playerManager] _ in
                guard let playerManager = playerManager else { return .commandFailed }
                
                if let currentSong = playerManager.currentSong {
                    playerManager.playNext()
                    return .success
                }
                return .commandFailed
            }
        
        //seek, 막대바 이동
        commandCenter.changePlaybackPositionCommand.addTarget { [weak playerManager] event in
            guard let playerManager = playerManager,
                  let positionEvent = event as? MPChangePlaybackPositionCommandEvent else {
                return .commandFailed
            }
            
            print("🎵 사용자 요청 시크 위치: \(positionEvent.positionTime)초")
            playerManager.seek(to: positionEvent.positionTime)
            return .success
        }
    }

    // MARK: - Now Playing 정보 설정
    func setupNowPlayingInfo(for song: Song, player: AVPlayer?) {
        guard let player = player else {
            print("❌ setupNowPlayingInfo - player가 nil 상태입니다.")
            return
        }

        let teamImage = UIImage(named: song.teamImageName) ?? UIImage()
        let imageWithWhiteBackground = addWhiteBackground(to: teamImage)
        
        let artwork = MPMediaItemArtwork(boundsSize: imageWithWhiteBackground.size){ _ in
            return imageWithWhiteBackground
        }

        var nowPlayingInfo: [String: Any] = [
            MPMediaItemPropertyTitle: song.title,
            MPMediaItemPropertyArtist: "응원가",
            MPNowPlayingInfoPropertyElapsedPlaybackTime: player.currentTime().seconds,
            MPMediaItemPropertyPlaybackDuration: player.currentItem?.duration.seconds ?? 0,
            MPNowPlayingInfoPropertyPlaybackRate: player.rate,
            MPMediaItemPropertyArtwork: artwork
        ]

        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
        print("✅ Now Playing 정보 업데이트됨: \(song.title)")
    }

    // MARK: 제어센터에서 고정된 정보 업데이트, 한번만 호출
    func updateNowPlayingInfo() {
        guard let player = AudioPlayerManager.shared.player,
              let currentSong = AudioPlayerManager.shared.currentSong else { return }

        let teamImage = UIImage(named: currentSong.teamImageName) ?? UIImage()
        let artwork = MPMediaItemArtwork(boundsSize: teamImage.size) { _ in teamImage }

        var nowPlayingInfo: [String: Any] = [
            MPMediaItemPropertyTitle: currentSong.title,
            MPMediaItemPropertyArtist: "응원가",
            MPNowPlayingInfoPropertyElapsedPlaybackTime: player.currentTime().seconds,
            MPMediaItemPropertyPlaybackDuration: player.currentItem?.duration.seconds ?? 0,
            MPNowPlayingInfoPropertyPlaybackRate: player.rate,
            MPMediaItemPropertyArtwork: artwork
        ]

        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo

        // ✅ Store the current song in UserDefaults so it's restored in the background
        let songData = try? JSONEncoder().encode(currentSong)
        UserDefaults.standard.set(songData, forKey: "currentSong")
        UserDefaults.standard.set(player.currentTime().seconds, forKey: "currentTime")

        print("✅ Now Playing 정보 업데이트됨: \(currentSong.title)")
    }

    // MARK: 이미지를 감싸는 배경 색 변경
    private func addWhiteBackground(to image: UIImage) -> UIImage {
        let newSize = CGSize(width: image.size.width, height: image.size.height)
        
        UIGraphicsBeginImageContextWithOptions(newSize, true, 0.0)
        UIColor.white.setFill()
        UIRectFill(CGRect(origin: .zero, size: newSize))

        image.draw(in: CGRect(origin: .zero, size: newSize))
        let imageWithBackground = UIGraphicsGetImageFromCurrentImageContext() ?? image
        UIGraphicsEndImageContext()

        return imageWithBackground
    }
    
    // MARK: 음원 업데이트 -> title, 이미지 등 동적인 변화
    func updateNowPlayingPlaybackState(for player: AVPlayer?, duration: Double) {
        guard let player = player else { return }

        var nowPlayingInfo = MPNowPlayingInfoCenter.default().nowPlayingInfo ?? [:]

        nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = player.currentTime().seconds
        nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = player.rate
        nowPlayingInfo[MPMediaItemPropertyPlaybackDuration] = player.currentItem?.duration.seconds ?? duration

        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
    }

    // 앱 백그라운드 감지 및 대응
    @objc private func handleAppDidEnterBackground() {
        print("📲 App moved to background - ensuring audio stays active")
        AVPlayerBackgroundManager.configureAudioSession()

        DispatchQueue.main.async {
            AudioPlayerManager.shared.backgroundManager.updateNowPlayingInfo()
        }
    }

    @objc private func handleAppWillEnterForeground() {
        print("📲 App moved to foreground - restoring session")
        AVPlayerBackgroundManager.configureAudioSession()
    }

    // MARK: - 인터럽션 및 라우트 변경 처리
    @objc private func handleInterruption(notification: Notification) {
        guard let info = notification.userInfo,
              let typeValue = info[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: typeValue) else { return }

        if type == .began {
            AudioPlayerManager.shared.pause()
        } else if type == .ended {
            if let optionsValue = info[AVAudioSessionInterruptionOptionKey] as? UInt,
               optionsValue == AVAudioSession.InterruptionOptions.shouldResume.rawValue,
               let currentUrl = AudioPlayerManager.shared.getCurrentUrl(),
               let currentSong = AudioPlayerManager.shared.currentSong {
                AudioPlayerManager.shared.play(url: currentUrl, for: currentSong)
            }
        }
    }

    // MARK: 오디오 경로 변경 감지
    @objc private func handleRouteChange(notification: Notification) {
        guard let userInfo = notification.userInfo,
              let reasonValue = userInfo[AVAudioSessionRouteChangeReasonKey] as? UInt,
              let reason = AVAudioSession.RouteChangeReason(rawValue: reasonValue) else { return }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { // ✅ 세션 변경을 기다린 후 실행
            switch reason {
            case .oldDeviceUnavailable: // 🎧 이어폰 제거됨 → 자동 일시정지
                print("🎧 이어폰이 제거됨 → 자동 일시정지")
                if AudioPlayerManager.shared.isPlaying {
                    AudioPlayerManager.shared.pause()
                    AudioPlayerManager.shared.objectWillChange.send()
                }

            case .newDeviceAvailable: // 🎧 이어폰 연결됨 → 기존 곡 그대로 재생
                print("🎧 새로운 오디오 장치 연결됨 → 기존 위치에서 다시 재생")

                if let player = AudioPlayerManager.shared.player,
                   let currentSong = AudioPlayerManager.shared.currentSong,
                   let currentUrl = AudioPlayerManager.shared.getCurrentUrl() {
                    
                    let savedTime = AudioPlayerManager.shared.currentTime // ✅ 이전 재생 위치 저장
                    print("🔁 이어폰 연결됨, 이전 재생 위치: \(savedTime)초")

                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { // ✅ 짧은 딜레이 후 재생
                        player.seek(to: CMTime(seconds: savedTime, preferredTimescale: 600)) // ✅ 이전 위치 유지
                        player.play()
                        AudioPlayerManager.shared.isPlaying = true
                        AudioPlayerManager.shared.objectWillChange.send()
                    }
                } else {
                    print("⚠️ 현재 곡 정보가 없어서 자동 재생 불가")
                }

            default:
                break
            }
        }
    }
}

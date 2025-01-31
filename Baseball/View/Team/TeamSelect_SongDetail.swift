//
//  SwiftUIView.swift
//     
//
//  Created by 곽현우 on 1/24/25.
//

import SwiftUI
import AVKit

struct SongDetailView: View {
    let song: Song
    @State private var player: AVPlayer?
    @State private var isPlaying: Bool = false
    @State private var currentTime: Double = 0
    @State private var duration: Double = 0
    @State private var playerObserver: Any?

    var body: some View {
        VStack(spacing: 20) {
            // 제목
            Text(song.title)
                .font(.largeTitle)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
                .padding()

            // 가사
            ScrollView {
                Text(song.lyrics)
                    .padding()
                    .background(Color(uiColor: .secondarySystemBackground))
                    .cornerRadius(10)
            }

            // 음원 진행 상태
            if duration > 0 {
                ProgressView(value: currentTime / duration)
                    .padding()
                HStack {
                    Text("\(formatTime(currentTime))")
                    Spacer()
                    Text("-\(formatTime(duration - currentTime))")
                }
            }

            // 음원 재생/일시정지 버튼
            Button(action: togglePlayPause) {
                Text(isPlaying ? "일시정지" : "재생")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(isPlaying ? Color.gray : Color.blue)
                    .cornerRadius(10)
            }
        }
        .padding()
        .onAppear(perform: setupPlayer)
        .onDisappear {
            player?.pause()
            if let observer = playerObserver {
                player?.removeTimeObserver(observer)
            }
        }
    }

    // MARK: - Audio Player Setup
    private func setupPlayer() {
        guard let url = URL(string: song.audioUrl) else { return }

        // AVPlayer 및 AVPlayerItem 설정
        player = AVPlayer(url: url)
        let playerItem = player?.currentItem ?? AVPlayerItem(url: url)
        
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

    // MARK: - Play / Pause Toggle
    private func togglePlayPause() {
        if isPlaying {
            player?.pause()
        } else {
            player?.play()
        }
        isPlaying.toggle()
    }

    // MARK: - 시간 포맷팅
    private func formatTime(_ time: Double) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

//#Preview {
//    SongDetailView(song: <#Song#>)
//}

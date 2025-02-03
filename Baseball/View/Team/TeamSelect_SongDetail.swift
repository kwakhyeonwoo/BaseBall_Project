//
//  SwiftUIView.swift
//     
//
//  Created by 곽현우 on 1/24/25.
//

import SwiftUI

struct SongDetailView: View {
    let song: Song
    @StateObject private var playerManager = AudioPlayerManager.shared

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
            if playerManager.duration > 0 {
                ProgressView(value: playerManager.currentTime / playerManager.duration)
                    .padding()
                HStack {
                    Text("\(formatTime(playerManager.currentTime))")
                    Spacer()
                    Text("-\(formatTime(playerManager.duration - playerManager.currentTime))")
                }
            }

            // 음원 재생/일시정지 버튼
            Button(action: togglePlayPause) {
                Text(playerManager.isPlaying ? "일시정지" : "재생")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(playerManager.isPlaying ? Color.gray : Color.blue)
                    .cornerRadius(10)
            }
        }
        .padding()
        .onAppear(perform: setupPlayer)
    }

    private func setupPlayer() {
        guard let url = URL(string: song.audioUrl) else { return }
        playerManager.play(url: url, for: song)
    }

    private func togglePlayPause() {
        if playerManager.isPlaying {
            playerManager.pause()
        } else {
            // 현재 URL과 비교하여 이미 재생 중인 플레이어인지 확인
            if playerManager.getCurrentUrl() != URL(string: song.audioUrl) {
                setupPlayer()  // 다른 음원이 선택된 경우 새로 설정
            }
            playerManager.play(url: URL(string: song.audioUrl)!, for: song)
        }
    }


    private func formatTime(_ time: Double) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

//#Preview {
//    SongDetailView(song: <#Song#>)
//}

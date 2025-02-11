//
//  SwiftUIView.swift
//     
//
//  Created by 곽현우 on 1/24/25.
//

import SwiftUI

struct SongDetailView: View {
    let song: Song
    let selectedTeam: String  // 추가된 팀 이름
    @Environment(\.presentationMode) var presentationMode
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

            // 팀 컬러 막대바
            if playerManager.duration > 0 {
                CustomProgressBar(
                    progress: .constant(playerManager.currentTime / playerManager.duration),
                    onSeek: { newProgress in
                        let newTime = newProgress * playerManager.duration
                        playerManager.seek(to: newTime)
                    },
                    teamColor: TeamColorModel.shared.getColor(for: selectedTeam)
                )
                .frame(height: 8)  // 높이를 줄여서 더 시각적으로 깔끔하게
                .padding(.horizontal, 20)  // 기존과 유사한 간격 설정
                .padding(.top, 5)  // 시간과의 간격 조정

                HStack {
                    Text("\(formatTime(playerManager.currentTime))")
                    Spacer()
                    Text("-\(formatTime(playerManager.duration - playerManager.currentTime))")
                }
                .padding()
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
        .onAppear(perform: setupPlayerIfNeeded)
        .onReceive(playerManager.$didFinishPlaying) { didFinish in
            if didFinish {
                presentationMode.wrappedValue.dismiss()

                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    playerManager.didFinishPlaying = false
                }
            }
        }
    }

    private func setupPlayerIfNeeded() {
        guard playerManager.getCurrentUrl() != URL(string: song.audioUrl) else { return }
        guard let url = URL(string: song.audioUrl) else { return }
        playerManager.play(url: url, for: song)
    }

    private func togglePlayPause() {
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

    private func formatTime(_ time: Double) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

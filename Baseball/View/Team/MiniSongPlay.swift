//
//  MiniSongPlay.swift
//     
//
//  Created by 곽현우 on 2/5/25.
//

import SwiftUI
import AVKit

struct MiniPlayerView: View {
    @StateObject private var playerManager = AudioPlayerManager.shared
    @State private var isShowingDetailView: Bool = false
    let selectedTeam: String  // 선택된 팀 이름

    var body: some View {
        if let currentSong = playerManager.currentSong {
            // 막대바를 ZStack으로 변경해서 간격 조절해야 되나
            VStack(alignment: .leading) {
                CustomProgressBar(
                    progress: .constant(playerManager.currentTime / playerManager.duration),
                    onSeek: { newProgress in
                        let newTime = newProgress * playerManager.duration
                        playerManager.seek(to: newTime)
                    },
                    teamColor: TeamColorModel.shared.getColor(for: selectedTeam)
                )
                .frame(height: 14)  // MiniPlayer에 적합한 높이로 조정
                .padding(.horizontal, 10)  // 여백 설정


                VStack(spacing: 10) {
                    miniPlayerContent(for: currentSong)
                }
                .padding([.horizontal, .bottom], 10)
                .background(Color(uiColor: .systemBackground))
                .cornerRadius(12)
                .shadow(radius: 2)
                .sheet(isPresented: $isShowingDetailView) {
                    SongDetailView(song: currentSong, selectedTeam: selectedTeam)  // 팀 이름 전달
                }
            }
            .animation(.spring(), value: playerManager.isPlaying)
        }
    }

    private func miniPlayerContent(for song: Song) -> some View {
        HStack(spacing: 10) {
            albumArtwork(for: song)

            VStack(alignment: .leading, spacing: 5) {
                Text(song.title)
                    .font(.headline)
                    .foregroundColor(.primary)
                    .lineLimit(1)

                Text(playerManager.isPlaying ? "재생 중" : "일시 정지")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            Spacer()

            playbackControls(for: song)
        }
        .padding(10)
        .onTapGesture {
            isShowingDetailView = true
        }
    }

    private func albumArtwork(for song: Song) -> some View {
        Image(song.teamImageName)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: 50, height: 50)
            .cornerRadius(8)
            .clipped()
    }

    private func playbackControls(for song: Song) -> some View {
        Button(action: {
            if playerManager.isPlaying {
                playerManager.pause()
            } else {
                if playerManager.currentUrl == URL(string: song.audioUrl) {
                    // ✅ Resume playback instead of reloading the song
                    playerManager.resume()
                } else {
                    // ✅ If a different song is selected, start playback from the beginning
                    if let url = URL(string: song.audioUrl) {
                        playerManager.play(url: url, for: song)
                    } else {
                        print("❌ Error: Invalid URL for song \(song.title)")
                    }

                }
            }
        }) {
            Image(systemName: playerManager.isPlaying ? "pause.fill" : "play.fill")
                .foregroundColor(.primary)
                .font(.system(size: 24, weight: .bold))
                .frame(width: 40, height: 40)
                .background(Color(uiColor: .secondarySystemBackground))
                .clipShape(Circle())
        }
    }


    private func showSongDetailView() {
        isShowingDetailView = true
    }
}

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

    var body: some View {
        if let currentSong = playerManager.currentSong {
            VStack {
                miniPlayerContent(for: currentSong)
            }
            .padding([.horizontal, .bottom], 10)
            .background(Color(uiColor: .systemBackground).shadow(radius: 2))
            .cornerRadius(12)
            .transition(.move(edge: .bottom))
            .animation(.spring(), value: playerManager.isPlaying)
            .sheet(isPresented: $isShowingDetailView) {
                SongDetailView(song: currentSong)
            }
        }
    }

    private func miniPlayerContent(for song: Song) -> some View {
        HStack {
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
            showSongDetailView()
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
            playerManager.isPlaying ? playerManager.pause() : playerManager.play(url: playerManager.getCurrentUrl()!, for: song)
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
        // 뷰 전환 애니메이션 적용
        isShowingDetailView = true
    }
}

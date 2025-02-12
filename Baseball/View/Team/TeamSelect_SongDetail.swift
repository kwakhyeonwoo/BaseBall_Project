//
//  SwiftUIView.swift
//     
//
//  Created by 곽현우 on 1/24/25.
//

import SwiftUI
import AVKit
import AVFoundation
import Combine
import MediaPlayer

struct SongDetailView: View {
    let song: Song
    let selectedTeam: String
    @Environment(\.presentationMode) var presentationMode
    @StateObject private var viewModel = SongDetailViewModel()

    var body: some View {
        VStack(spacing: 20) {
            Text(song.title)
                .font(.largeTitle)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
                .padding()

            ScrollView {
                Text(song.lyrics)
                    .padding()
                    .background(Color(uiColor: .secondarySystemBackground))
                    .cornerRadius(10)
            }

            if viewModel.duration > 0 {
                CustomProgressBar(
                    progress: $viewModel.progress, // ✅ Binding을 직접 사용하여 실시간 반영
                    onSeek: { newProgress in
                        let newTime = newProgress * max(1, viewModel.duration)
                        viewModel.seek(to: newTime)
                    },
                    teamColor: TeamColorModel.shared.getColor(for: selectedTeam)
                )

                .frame(height: 8)
                .padding(.horizontal, 20)
                .padding(.top, 5)
                
                HStack {
                    Text(formatTime(viewModel.currentTime)) // ✅ 직접 값 참조
                    Spacer()
                    Text("-" + formatTime(viewModel.duration - viewModel.currentTime)) // ✅ duration도 다시 참조 가능하도록 수정
                }
                .padding()
            }

            HStack {
                Button(action: viewModel.playPrevious) {
                    Image(systemName: "backward.fill")
                        .font(.system(size: 30))
                        .foregroundColor(viewModel.hasPreviousSong() ? .primary : .gray)
                }
                .disabled(!viewModel.hasPreviousSong())

                Spacer()

                Button(action: { viewModel.togglePlayPause(for: song) }) {
                    Image(systemName: viewModel.isPlaying ? "pause.fill" : "play.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.white)
                        .padding()
                        .background(viewModel.isPlaying ? Color.gray : Color.blue)
                        .clipShape(Circle())
                }

                Spacer()

                Button(action: viewModel.playNext) {
                    Image(systemName: "forward.fill")
                        .font(.system(size: 30))
                        .foregroundColor(viewModel.hasNextSong() ? .primary : .gray)
                }
                .disabled(!viewModel.hasNextSong())
            }
            .padding(.top, 10)
        }
        .padding()
        .onAppear { viewModel.setupPlayerIfNeeded(for: song) }
        .onReceive(viewModel.$didFinishPlaying) { didFinish in
            if didFinish {
                presentationMode.wrappedValue.dismiss()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    viewModel.resetFinishState()
                }
            }
        }
    }
    
    private func formatTime(_ time: Double) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

//
//  SwiftUIView.swift
//
//
//  Created by 곽현우 on 1/24/25.
//

import SwiftUI
import AVFoundation
import Combine

struct SongDetailView: View {
    let song: Song
    let selectedTeam: String
    @Environment(\.presentationMode) var presentationMode

    @ObservedObject private var playerManager = AudioPlayerManager.shared

    @State private var lyricsLines: [String] = []
    @State private var activeLineIndex: Int = -1
    @State private var scrollProxy: ScrollViewProxy? = nil

    var body: some View {
        ZStack {
            Image("\(selectedTeam)")
                .resizable()
                .scaledToFit()
                .frame(width: 250, height: 250)
                .opacity(0.2)
                .offset(y: -30)

            VStack(spacing: 20) {
                Text(playerManager.currentSong?.title ?? song.title)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                    .padding()

                ScrollViewReader { proxy in
                    ScrollView {
                        VStack(alignment: .leading, spacing: 20) {
                            ForEach(lyricsLines.indices, id: \.self) { index in
                                Text(lyricsLines[index])
                                    .font(.title2)
                                    .fontWeight(index == activeLineIndex ? .bold : .regular)
                                    .foregroundColor(index == activeLineIndex ? .green : .primary)
                                    .multilineTextAlignment(.center)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 8)
                                    .id(index)
                            }
                        }
                        .padding(.horizontal, 40)
                    }
                    .onAppear { scrollProxy = proxy }
                }

                if playerManager.duration > 0 {
                    CustomProgressBar(
                        progress: .constant(playerManager.currentTime / max(1, playerManager.duration)),
                        onSeek: { newProgress in
                            let newTime = newProgress * max(1, playerManager.duration)
                            playerManager.seek(to: newTime)
                        },
                        teamColor: TeamColorModel.shared.getColor(for: selectedTeam)
                    )
                    .frame(height: 8)
                    .padding(.horizontal, 20)
                    .padding(.top, 5)

                    HStack {
                        Text(formatTime(playerManager.currentTime))
                        Spacer()
                        Text("-" + formatTime(playerManager.duration - playerManager.currentTime))
                    }
                    .padding()
                }

                HStack {
                    Button(action: { playerManager.playPrevious() }) {
                        Image(systemName: "backward.fill")
                            .font(.system(size: 30))
                            .foregroundColor(.primary)
                            .frame(width: 50, height: 50)
                    }

                    Spacer()

                    Button(action: {
                        if playerManager.isPlaying {
                            playerManager.pause()
                        } else {
                            if let url = URL(string: song.audioUrl) {
                                playerManager.play(url: url, for: song)
                            }
                        }
                    }) {
                        Image(systemName: playerManager.isPlaying ? "pause.fill" : "play.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.white)
                            .padding()
                            .background(playerManager.isPlaying ? Color.gray : Color.blue)
                            .clipShape(Circle())
                            .frame(width: 70, height: 70)
                    }

                    Spacer()

                    Button(action: { playerManager.playNext() }) {
                        Image(systemName: "forward.fill")
                            .font(.system(size: 30))
                            .foregroundColor(.primary)
                            .frame(width: 50, height: 50)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
            }
            .padding()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.white)
        .edgesIgnoringSafeArea(.all)
        .onAppear {
            updateLyricsLines()
            AVPlayerBackgroundManager.configureAudioSession()
        }
        .onChange(of: playerManager.currentSong) { _ in
            updateLyricsLines()
        }
        .onReceive(playerManager.$currentTime) { currentTime in
            updateHighlightedLyric(for: currentTime)
        }
    }
    
    private func updateLyricsLines() {
        if let lyrics = playerManager.currentSong?.lyrics {
            lyricsLines = formatLyrics(lyrics)
            activeLineIndex = -1
        }
    }

    private func formatLyrics(_ lyrics: String) -> [String] {
        return lyrics
            .replacingOccurrences(of: "\\n\\n", with: "\n\n")
            .components(separatedBy: "\n\n")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }

    private func updateHighlightedLyric(for time: Double) {
        guard let timestamps = playerManager.currentSong?.timestamps else { return }
        let startTime = playerManager.currentSong?.lyricsStartTime ?? 0

        var adjustedTimestamps = timestamps
        if adjustedTimestamps.count != lyricsLines.count - 1 {
            while adjustedTimestamps.count < lyricsLines.count - 1 {
                adjustedTimestamps.append(adjustedTimestamps.last ?? startTime)
            }
            while adjustedTimestamps.count > lyricsLines.count - 1 {
                adjustedTimestamps.removeLast()
            }
        }

        if time < startTime {
            activeLineIndex = -1
            return
        }

        if let newIndex = adjustedTimestamps.lastIndex(where: { $0 <= time }) {
            let highlightIndex = min(newIndex + 1, lyricsLines.count - 1)
            if highlightIndex != activeLineIndex {
                activeLineIndex = highlightIndex
                withAnimation {
                    scrollProxy?.scrollTo(highlightIndex, anchor: .center)
                }
            }
        } else {
            activeLineIndex = lyricsLines.count - 1
        }
    }

    private func formatTime(_ time: Double) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

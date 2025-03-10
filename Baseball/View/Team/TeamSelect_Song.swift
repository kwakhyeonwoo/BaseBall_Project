//
//  TeamSelect_Song.swift
//  Baseball
//
//  Created by 곽현우 on 12/28/24.
//

import SwiftUI
import AVKit

struct TeamSelect_SongView: View {
    let selectedTeam: String
    let selectedTeamImage: String
    @StateObject private var viewModel = TeamSelectSongViewModel()
    @StateObject private var playerManager = AudioPlayerManager.shared
    @State private var player: AVPlayer? = nil
    @State private var selectedSong: Song? = nil
    @State private var isDetailPresented: Bool = false

    var body: some View {
        NavigationView {
            ZStack (alignment: .bottom){
                VStack {
                    categoryPicker()
                    if !viewModel.songs.isEmpty {
                        HStack {
                            Text("[총 \(viewModel.songs.count)곡]")
                                .font(.caption)
                                .foregroundColor(.gray)
                                .padding(.leading)
                            Spacer()
                        }
                    }
                    
                    if viewModel.isLoading {
                        ProgressView("로딩 중...")
                    } else if !viewModel.songs.isEmpty {
                        songListView()
                    } else {
                        Text("응원가 정보를 불러올 수 없습니다.")
                            .foregroundColor(.red)
                            .padding()
                    }
                    Spacer()
                    
                }
                .onAppear {
                    viewModel.fetchSongs(for: selectedTeam)
                }
                .sheet(item: $selectedSong, onDismiss: {
                    // ✅ Ensure selectedSong is reset when detail view is dismissed
                    selectedSong = nil
                }) { song in
                    SongDetailView(song: song, selectedTeam: selectedTeam)
                }
                // 하단부에 현재 음원 출력
                if playerManager.currentSong != nil {
                    MiniPlayerView(selectedTeam: selectedTeam)
                        .padding(.bottom, 10)
                        .transition(.move(edge: .bottom))
                        .animation(.spring(), value: playerManager.currentSong)
                }
            }
        }
    }

    // MARK: - Category Picker
    private func categoryPicker() -> some View {
        Picker("Category", selection: $viewModel.selectedCategory) {
            Text("팀 응원가").tag(SongCategory.teamSongs)
            Text("선수 응원가").tag(SongCategory.playerSongs)
        }
        .pickerStyle(SegmentedPickerStyle())
        .padding()
        .onChange(of: viewModel.selectedCategory) { _ in
            viewModel.fetchSongs(for: selectedTeam)
        }
    }

    // MARK: - Song List View
    private func songListView() -> some View {
        ScrollView {
            VStack(spacing: 20) {
                ForEach(viewModel.songs) { song in
                    songCard(song: song)
                }
            }
            .padding()
            .padding(.bottom, playerManager.currentSong == nil ? 0 : 100)
        }
    }

    // MARK: - Song Card
    private func songCard(song: Song) -> some View {
        HStack {
            Image(selectedTeamImage)
                .resizable()
                .scaledToFit()
                .frame(width: 50, height: 50)
                .clipShape(Circle())
            
            Text(song.title)
                .font(.headline)
                .foregroundColor(.primary)
                .padding(.leading, 10)
                .onTapGesture {
                    selectedSong = song
                    viewModel.setupAndPlaySong(song)
                }
            
            Spacer()
            
            Button(action: {
                viewModel.toggleFavorite(song: song)
            }) {
                Image(systemName: viewModel.isFavorite(song: song) ? "heart.fill" : "heart")
                    .foregroundColor(viewModel.isFavorite(song: song) ? .red : .gray)
                    .font(.title2)
            }
        }
        .padding()
        .background(Color(uiColor: .secondarySystemBackground))
        .cornerRadius(10)
        .shadow(radius: 5)
    }
}


#Preview {
    TeamSelect_SongView(selectedTeam: "SSG", selectedTeamImage: "SSG")
}

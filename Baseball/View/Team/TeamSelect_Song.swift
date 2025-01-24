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
    @State private var selectedSong: Song? = nil // 선택된 Song
    @State private var isDetailPresented: Bool = false

    var body: some View {
        NavigationView {
            VStack {
                categoryPicker()
                Spacer()
                if viewModel.isLoading {
                    ProgressView("로딩 중...")
                } else if !viewModel.songs.isEmpty {
                    songListView()
                } else {
                    Text("응원가 정보를 불러올 수 없습니다.")
                        .foregroundColor(.red)
                        .padding()
                }
            }
            .navigationTitle("\(selectedTeam) 응원가")
            .onAppear {
                viewModel.fetchSongs(for: selectedTeam)
            }
            .sheet(item: $selectedSong) { song in
                SongDetailView(song: song)
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

//
//  myPage.swift
//  Baseball
//
//  Created by 곽현우 on 12/28/24.
//

import SwiftUI

struct MyPageView: View {
    let selectedTeam: String
    let selectedTeamImage: String

    @StateObject private var viewModel = MyPageViewModel()
    @StateObject private var playerManager = AudioPlayerManager.shared

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                VStack(alignment: .leading, spacing: 24) {
                    userHeader()
                    Divider().padding(.horizontal, 20)
                    likedTeamSongSection()
                    Divider().padding(.horizontal, 20)
                    likedUploadedSongSection()
                    Spacer(minLength: 40)
                }

                // ✅ MiniPlayerView (응원가 재생 시)
                if playerManager.currentSong != nil {
                    MiniPlayerView(selectedTeam: selectedTeam)
                        .padding(.bottom, 10)
                        .transition(.move(edge: .bottom))
                        .animation(.spring(), value: playerManager.currentSong)
                }
            }
            .navigationTitle("보관함")
            .onAppear {
                viewModel.fetchNickname()
                viewModel.fetchLikedTeamSongs(for: selectedTeam)
                viewModel.fetchLikedUploadedSongs()
            }
        }
    }

    // MARK: - 사용자 프로필 헤더
    private func userHeader() -> some View {
        HStack {
            Image(selectedTeamImage)
                .resizable()
                .frame(width: 32, height: 32)
                .clipShape(Circle())
                .scaledToFit()

            Text(viewModel.nickname.isEmpty ? "닉네임 불러오는 중..." : viewModel.nickname)
                .font(.title2)
                .bold()

            Spacer()

            Button("로그아웃") {
                // 로그아웃 처리
            }
            .foregroundColor(.red)
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
    }

    // MARK: - 좋아요 한 응원가 (세로)
    private func likedTeamSongSection() -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("좋아요 한 응원가")
                .font(.headline)
                .padding(.horizontal, 20)

            if viewModel.likedTeamSongs.isEmpty {
                Text("좋아요한 응원가가 없습니다.")
                    .foregroundColor(.gray)
                    .padding(.horizontal, 20)
            } else {
                ScrollView {
                    VStack(spacing: 16) {
                        ForEach(Array(viewModel.likedTeamSongs.enumerated()), id: \.element.id) { index, song in
                            VStack(spacing: 8) {
                                HStack {
                                    Image(selectedTeamImage)
                                        .resizable()
                                        .frame(width: 40, height: 40)
                                        .padding(6)
                                        .background(Color.gray.opacity(0.2))
                                        .cornerRadius(10)

                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(song.title)
                                            .font(.headline)
                                    }

                                    Spacer()
                                }
                                .padding(.horizontal, 20)
                                .onTapGesture {
                                    if let url = URL(string: song.audioUrl) {
                                        playerManager.play(url: url, for: song)
                                    }
                                }

                                // ✅ 마지막 항목엔 Divider 생략
                                if index < viewModel.likedTeamSongs.count - 1 {
                                    Divider()
                                        .padding(.horizontal, 20)
                                        .padding(.vertical, 8)
                                }
                            }
                        }
                    }
                    .padding(.vertical, 5)
                }
                .frame(height: 400)
            }
        }
    }

    // MARK: - 업로드 한 응원가 (가로)
    private func likedUploadedSongSection() -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("업로드 한 응원가")
                .font(.headline)
                .padding(.horizontal, 20)

            if viewModel.likedUploadedSongs.isEmpty {
                Text("업로드한 응원가가 없습니다.")
                    .foregroundColor(.gray)
                    .padding(.horizontal, 20)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        ForEach(viewModel.likedUploadedSongs) { song in
                            VStack(alignment: .leading) {
                                Image(systemName: "video.fill")
                                    .resizable()
                                    .frame(width: 80, height: 80)
                                    .background(Color.gray.opacity(0.2))
                                    .cornerRadius(8)

                                Text(song.title)
                                    .font(.caption)
                                    .lineLimit(1)
                                    .frame(width: 80, alignment: .leading)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                }
                .frame(height: 120)
            }
        }
    }
}


//#Preview {
//    myPage()
//}

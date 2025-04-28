//
//  CheckAllVideo.swift
//
//
//  Created by 곽현우 on 2/27/25.
//

import SwiftUI

struct CheckAllVideo: View {
    let selectedTeam: String
    let selectedTeamImage: String

    @StateObject private var viewModel = CheckAllVideoViewModel()
    @State private var selectedCategory: UploadedSongCategory = .uploaded
    @State private var showToast = false
    @State private var uploadedTitle = ""

    var body: some View {
        NavigationView {
            VStack {
                Picker("Category", selection: $selectedCategory) {
                    Text("업로드 응원가").tag(UploadedSongCategory.uploaded)
                    Text("인기 응원가").tag(UploadedSongCategory.popular)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()
                .onChange(of: selectedCategory) { _ in
                    viewModel.loadUploadedSongs()
                }

                ScrollView {
                    VStack(spacing: 15) {
                        ForEach(viewModel.uploadedSongs) { song in
                            HStack {
                                Image(selectedTeamImage)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 50, height: 50)
                                    .clipShape(Circle())

                                VStack(alignment: .leading, spacing: 5) {
                                    Text(song.uploader)
                                        .font(.footnote)
                                        .foregroundColor(.gray)

                                    Text(song.title)
                                        .font(.headline)
                                        .foregroundColor(.primary)
                                }

                                Spacer()

                                VStack {
                                    Button(action: {
                                        viewModel.toggleLike(for: song)
                                    }) {
                                        Image(systemName: viewModel.likedSongs.contains(song.id) ? "heart.fill" : "heart")
                                            .foregroundColor(viewModel.likedSongs.contains(song.id) ? .red : .gray)
                                            .font(.title2)
                                    }

                                    Text("\(viewModel.likeCounts[song.id, default: 0])")
                                        .font(.footnote)
                                        .foregroundColor(.gray)
                                }
                            }
                            .padding()
                            .background(Color(.secondarySystemBackground))
                            .cornerRadius(10)
                            .shadow(radius: 2)
                            .onTapGesture {
                                viewModel.playVideo(song: song)
                            }
                        }
                    }
                    .padding()
                }
            }
            .onAppear {
                viewModel.loadUploadedSongs()
            }
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("RefreshUploadedSongs"))) { _ in
                viewModel.loadUploadedSongs()
            }
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("UploadSuccess"))) { notification in
                if let userInfo = notification.userInfo, let title = userInfo["title"] as? String {
                    self.uploadedTitle = title
                    self.showToast = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                        self.showToast = false
                    }
                }
            }
            .overlay(
                Group {
                    if showToast {
                        VStack {
                            Spacer()
                            Text("\(uploadedTitle)이/가 업로드 되었습니다!")
                                .font(.subheadline)
                                .padding()
                                .background(Color.black.opacity(0.8))
                                .foregroundColor(.white)
                                .cornerRadius(12)
                                .padding(.bottom, 30)
                                .transition(.move(edge: .bottom).combined(with: .opacity))
                                .animation(.easeInOut, value: showToast)
                        }
                    }
                }
            )
        }
    }
}


//#Preview {
//    CheckAllVideo()
//}

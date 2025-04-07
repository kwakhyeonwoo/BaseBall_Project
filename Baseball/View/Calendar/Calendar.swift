//
//  Calendar.swift
//  Baseball
//
//  Created by 곽현우 on 12/28/24.
//

import SwiftUI

struct CalendarView: View {
//    @StateObject private var viewModel = GameScheduleViewModel()
    @StateObject private var highlightFetcher = HighlightVideoFetcher()
    @StateObject var teamNewsManager = TeamNewsManager()
    let selectedTeam: String
    let selectedTeamImage: String
    @State private var selectedTab: String? = "경기일정"
    @State private var showVideoRecorder: Bool = false // 응원가 업로드 이동
    @State private var recordedVideoURL: URL? // 녹화된 영상 저장
    @State private var navigateToCheckAllVideo = false
    @State private var navigateToSongView = false // ✅ 공식 응원가 이동
    @State private var navigateToTitleInput = false
    @State private var showFullNewsView = false
    @State private var selectedURL: URL? = nil
    @State private var showFullHighlightView = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                // ✅ 배경 로고 이미지
                Image("\(selectedTeam)")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 200, height: 200)
                    .opacity(0.3)
                    .offset(y: -50)

                VStack(alignment: .leading, spacing: 0) {
                    // ✅ 뉴스 섹션
                    if !teamNewsManager.articles.isEmpty {
                        Button(action: {
                            showFullNewsView = true
                        }) {
                            Text("📢 \(selectedTeam) 최신 기사")
                                .font(.headline)
                                .padding(.bottom, 10)
                                .padding(.horizontal, 16)
                        }
                        List(teamNewsManager.articles) { article in
                            Button(action: {
                                if let url = URL(string: article.link) {
                                    selectedURL = url
                                }
                            }) {
                                Text(article.title)
                                    .font(.body)
                                    .foregroundColor(.black)
                                    .multilineTextAlignment(.leading)
                            }
                            .padding(.vertical, 5)
                        }
                        .listStyle(.plain)
                        .frame(height: 200)
                        .padding(.bottom, 20)
                    }
                    Divider()
                    Spacer()

                    // ✅ 하이라이트 영상 섹션
                    if !teamNewsManager.highlights.isEmpty {
                        Button(action: {
                            showFullHighlightView = true
                        }){
                            Text("📹 \(selectedTeam) 하이라이트")
                                .font(.headline)
                                .padding(.bottom, 10)
                                .padding(.horizontal, 16)
                        }

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(alignment: .top, spacing: 16) {
                                ForEach(teamNewsManager.highlights) { video in
                                    VStack(alignment: .leading, spacing: 6) {
                                        AsyncImage(url: URL(string: video.thumbnailURL)) { image in
                                            image
                                                .resizable()
                                                .aspectRatio(contentMode: .fill)
                                        } placeholder: {
                                            Color.gray
                                        }
                                        .frame(width: 140, height: 80)
                                        .clipped()
                                        .cornerRadius(8)

                                        Text(video.title)
                                            .font(.caption)
                                            .foregroundColor(.primary)
                                            .lineLimit(2)
                                            .frame(width: 140, alignment: .leading)
                                    }
                                    .onTapGesture {
                                        if let url = URL(string: video.videoURL) {
                                            selectedURL = url
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                        .padding(.bottom, 20)
                    }
                    Divider()
                    Spacer()
                    tabView()
                }
                .padding()
            }
            .onAppear {
                print("📺 CalendarView appeared - fetching content for \(selectedTeam)")
                teamNewsManager.fetchContent(for: selectedTeam)
            }
            .sheet(isPresented: $showVideoRecorder, onDismiss: {
                if recordedVideoURL != nil {
                    navigateToTitleInput = true
                }
            }) {
                VideoRecorderViewModel { videoURL in
                    DispatchQueue.main.async {
                        if let videoURL = videoURL {
                            recordedVideoURL = videoURL
                        }
                    }
                }
            }
            .sheet(item: $selectedURL){ url in
                SafariView(url: url)
            }
            .background(
                VStack {
                    NavigationLink(
                        destination: UploadSongTitleView(
                            selectedTeam: selectedTeam,
                            selectedTeamImage: selectedTeamImage,
                            videoURL: recordedVideoURL
                        ),
                        isActive: $navigateToTitleInput
                    ) {
                        EmptyView()
                    }.hidden()

                    NavigationLink(
                        destination: CheckAllVideo(
                            selectedTeam: selectedTeam,
                            selectedTeamImage: selectedTeamImage
                        ),
                        isActive: $navigateToCheckAllVideo
                    ) {
                        EmptyView()
                    }.hidden()

                    NavigationLink(
                        destination: TeamSelect_SongView(
                            selectedTeam: selectedTeam,
                            selectedTeamImage: selectedTeamImage
                        ),
                        isActive: $navigateToSongView
                    ) {
                        EmptyView()
                    }.hidden()
                    
                    NavigationLink(
                        destination: TeamNewsFullView(
                            teamName: selectedTeam,
                            articles: teamNewsManager.articles
                        ),
                        isActive: $showFullNewsView
                    ) {
                        EmptyView()
                    }.hidden()
                    
                    NavigationLink(
                        destination: TeamVideoGrid(teamName: selectedTeam),
                        isActive: $showFullHighlightView
                    ) {
                        EmptyView()
                    }.hidden()
                }
            )
        }
    }

    func tabView() -> some View {
        HStack(spacing: 0) {
            tabButton(label: "경기일정", icon: "calendar", tag: "경기일정")
            tabButton(label: "공식 응원가", icon: "music.note", tag: "공식 응원가")
            tabButton(label: "응원가 업로드", icon: "arrow.up.circle", tag: "응원가 업로드")
            tabButton(label: "응원가 확인", icon: "play.rectangle", tag: "응원가 확인")
            tabButton(label: "보관함", icon: "tray.full", tag: "보관함")
        }
        .frame(height: 80)
        .background(Color.white)
        .padding(.horizontal, 10)
    }

    func tabButton(label: String, icon: String, tag: String) -> some View {
        Button(action: {
            selectedTab = tag
            if tag == "응원가 업로드" {
                showVideoRecorder = true
            } else if tag == "공식 응원가" {
                navigateToSongView = true // ✅ TeamSelect_SongView로 이동
            } else if tag == "응원가 확인"{
                navigateToCheckAllVideo = true
            }
        }) {
            VStack(spacing: 5) {
                Image(systemName: icon)
                    .font(.system(size: selectedTab == tag ? 26 : 24, weight: selectedTab == tag ? .bold : .regular))
                    .foregroundColor(.black)
                Text(label)
                    .font(.footnote)
                    .foregroundColor(.black)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.vertical, 10)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

//#Preview {
//    CalendarView(selectedTeam: , selectedTeamImage: <#String#>)
//}

//calendar,music.note,arrow.up.circle,tray.full

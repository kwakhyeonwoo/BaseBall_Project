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
    @State private var hasFetchedContent = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                mainContent()
            }
            .onAppear {
                guard !hasFetchedContent else { return } // ✅ 이미 불러왔으면 재요청 안함
                print("📺 CalendarView appeared - fetching content for \(selectedTeam)")
                teamNewsManager.fetchContent(for: selectedTeam)
                hasFetchedContent = true
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
            .sheet(item: $selectedURL) { url in
                SafariView(url: url)
            }
            .background(navigationLinks())
        }
    }

    func mainContent() -> some View {
        VStack(alignment: .leading, spacing: 0) {
            newsSection()
            Divider()
            Spacer()
            highlightSection()
            Divider()
            Spacer()
            tabView()
        }
        .padding()
    }

    //뉴스 기사 파싱
    func newsSection() -> some View {
        Group {
            if !teamNewsManager.articles.isEmpty {
                HStack{
                    Text("\(selectedTeam) 최신 기사")
                        .font(.headline)
                    Spacer()
                    
                    Button(
                        action: {
                            showFullNewsView = true
                        }) {
                        Text("전체화면")
                            .font(.caption2)
                            .foregroundColor(.gray)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 10)

                ScrollView {
                    VStack(alignment: .leading, spacing: 12) {
                        ForEach(teamNewsManager.articles) { article in
                            Button(action: {
                                if let url = URL(string: article.link) {
                                    selectedURL = url
                                }
                            }) {
                                VStack(alignment: .leading, spacing: 4) {
                                    if let date = article.pubDate {
                                        Text(dateFormatted(date)) // ex: 4월 9일
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                    }

                                    Text(article.title)
                                        .font(.subheadline)
                                        .foregroundColor(.primary)
                                        .multilineTextAlignment(.leading)
                                        .lineLimit(2)

                                    if let source = article.source {
                                        Text(source)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }

                                    Divider()
                                }
                                .padding(.horizontal, 16)
                            }
                        }
                    }
                    .padding(.top, 10)
                }
                .frame(height: 400)
                .padding(.bottom, 20)
            }
        }
    }

    //유튜브 영상
    func highlightSection() -> some View {
        Group {
            if !teamNewsManager.highlights.isEmpty {
                HStack{
                    Text("\(selectedTeam) 하이라이트")
                        .font(.headline)
                    Spacer()
                    Button(action: {
                        showFullHighlightView = true
                    }) {
                        Text("전체화면")
                            .font(.caption2)
                            .foregroundColor(.gray)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 10)

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
                                .frame(width: UIScreen.main.bounds.width * 0.4, height: 80)
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
        }
    }

    func navigationLinks() -> some View {
        VStack {
            NavigationLink(
                destination: UploadSongTitleView(
                    selectedTeam: selectedTeam,
                    selectedTeamImage: selectedTeamImage,
                    videoURL: recordedVideoURL
                ),
                isActive: $navigateToTitleInput
            ) { EmptyView() }.hidden()

            NavigationLink(
                destination: CheckAllVideo(
                    selectedTeam: selectedTeam,
                    selectedTeamImage: selectedTeamImage
                ),
                isActive: $navigateToCheckAllVideo
            ) { EmptyView() }.hidden()

            NavigationLink(
                destination: TeamSelect_SongView(
                    selectedTeam: selectedTeam,
                    selectedTeamImage: selectedTeamImage
                ),
                isActive: $navigateToSongView
            ) { EmptyView() }.hidden()

            NavigationLink(
                destination: TeamNewsFullView(
                    teamName: selectedTeam,
                    articles: teamNewsManager.articles
                ),
                isActive: $showFullNewsView
            ) { EmptyView() }.hidden()

            NavigationLink(
                destination: TeamVideoGrid(teamName: selectedTeam),
                isActive: $showFullHighlightView
            ) { EmptyView() }.hidden()
        }
    }

    //날짜 포맷
    func dateFormatted(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "M월 d일"
        return formatter.string(from: date)
    }


    func tabView() -> some View {
        HStack(spacing: 0) {
            tabButton(label: "일정", icon: "calendar", tag: "일정")
            tabButton(label: "응원가", icon: "music.note", tag: "응원가")
            tabButton(label: "업로드", icon: "arrow.up.circle", tag: "업로드")
            tabButton(label: "응원영상", icon: "play.rectangle", tag: "응원영상")
            tabButton(label: "보관함", icon: "tray.full", tag: "보관함")
        }
        .frame(height: 40)
        .background(Color.white)
        .padding(.horizontal, 10)
    }

    func tabButton(label: String, icon: String, tag: String) -> some View {
        Button(action: {
            selectedTab = tag
            if tag == "업로드" {
                showVideoRecorder = true
            } else if tag == "응원가" {
                navigateToSongView = true // ✅ TeamSelect_SongView로 이동
            } else if tag == "응원영상"{
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

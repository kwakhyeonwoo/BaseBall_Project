//
//  TeamVideoGrid.swift
//     
//
//  Created by 곽현우 on 4/3/25.
//

import SwiftUI

struct TeamVideoGrid: View {
    let teamName: String

    @StateObject private var viewModel = VideoArticleViewModel()
    @State private var videos: [HighlightVideo] = []
    @State private var selectedURL: URL?

    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(videos.indices, id: \.self) { index in
                    let video = videos[index]

                    VStack(alignment: .leading, spacing: 8) {
                        AsyncImage(url: URL(string: video.thumbnailURL)) { image in
                            image
                                .resizable()
                                .scaledToFill()
                        } placeholder: {
                            Color.gray
                        }
                        .frame(width: thumbnailWidth(), height: thumbnailHeight())
                        .clipped()
                        .cornerRadius(8)

                        Text(video.title)
                            .font(.caption)
                            .lineLimit(2)
                    }
                    .onAppear {
                        if index == videos.count - 3 { // 거의 끝에 도달 시
                            loadMore()
                        }
                    }
                    .onTapGesture {
                        if let url = URL(string: video.videoURL) {
                            selectedURL = url
                        }
                    }
                }
            }
            .padding()
        }
        .navigationTitle("\(teamName) 하이라이트")
        .sheet(item: $selectedURL) { url in
            SafariView(url: url)
        }
        .onAppear {
            viewModel.resetPagination()
            viewModel.fetchHighlights(for: teamName) { newVideos in
                DispatchQueue.main.async {
                    self.videos = newVideos
                }
            }
        }
    }

    func loadMore() {
        viewModel.fetchHighlights(for: teamName) { newVideos in
            DispatchQueue.main.async {
                self.videos.append(contentsOf: newVideos)
            }
        }
    }
    
    func thumbnailWidth() -> CGFloat {
        let screenWidth = UIScreen.main.bounds.width
        let spacing: CGFloat = 16 * 4 // 3개 항목 + 여백 여유분
        return (screenWidth - spacing) / 3
    }

    func thumbnailHeight() -> CGFloat {
        return thumbnailWidth() * 9 / 16 // ✅ 16:9 비율 유지
    }
}
//#Preview {
//    TeamVideoGrid()
//}

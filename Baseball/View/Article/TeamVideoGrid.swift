//
//  TeamVideoGrid.swift
//     
//
//  Created by 곽현우 on 4/3/25.
//

import SwiftUI

struct TeamVideoGrid: View {
    let teamName: String
    let videos: [HighlightVideo]

    @State private var selectedURL: URL?

    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(videos) { video in
                    VStack(alignment: .leading, spacing: 8) {
                        AsyncImage(url: URL(string: video.thumbnailURL)) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        } placeholder: {
                            Color.gray
                        }
                        .frame(height: 100)
                        .clipped()
                        .cornerRadius(8)

                        Text(video.title)
                            .font(.caption)
                            .lineLimit(2)
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
    }
}


//#Preview {
//    TeamVideoGrid()
//}

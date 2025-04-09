//
//  TeamArticle.swift
//     
//
//  Created by 곽현우 on 3/25/25.
//

import SwiftUI

struct TeamNewsFullView: View {
    let teamName: String
    let articles: [Article]

    @State private var selectedURL: URL?

    var body: some View {
        ScrollView {
            articleListView()
                .padding(.horizontal)
                .padding(.top, 12)
        }
        .navigationTitle("\(teamName) 뉴스")
        .sheet(item: $selectedURL) { url in
            SafariView(url: url)
        }
    }

    // MARK: - 기사 리스트 뷰
    func articleListView() -> some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(articles) { article in
                Button(action: {
                    if let url = URL(string: article.link) {
                        selectedURL = url
                    }
                }) {
                    VStack(alignment: .leading, spacing: 4) {
                        // 날짜
                        if let date = article.pubDate {
                            Text(dateFormatted(date))
                                .font(.caption)
                                .foregroundColor(.gray)
                        }

                        // 제목
                        Text(article.title)
                            .font(.subheadline)
                            .foregroundColor(.primary)
                            .multilineTextAlignment(.leading)
                            .lineLimit(2)

                        // 출판사
                        if let source = article.source {
                            Text(source)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, 8)
                }
                Divider()
                    .padding(.vertical, 4)
            }
        }
    }

    // MARK: - 날짜 포맷터
    func dateFormatted(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "M월 d일"
        return formatter.string(from: date)
    }
}

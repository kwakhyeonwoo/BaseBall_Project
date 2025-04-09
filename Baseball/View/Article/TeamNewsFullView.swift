//
//  TeamArticle.swift
//     
//
//  Created by 곽현우 on 3/25/25.
//

import SwiftUI

struct TeamNewsFullView: View {
    let teamName: String
    @StateObject private var viewModel = TeamNewsFullViewModel()
    @State private var selectedURL: URL?

    var body: some View {
        ScrollView {
            if viewModel.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.top, 60)
            } else {
                articleListView()
                    .padding(.horizontal)
                    .padding(.top, 12)
            }
        }
        .navigationTitle("\(teamName) 뉴스")
        .onAppear {
            viewModel.fetch(for: teamName)
        }
        .sheet(item: $selectedURL) { url in
            SafariView(url: url)
        }
    }

    @ViewBuilder
    private func articleListView() -> some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(viewModel.articles) { article in
                Button(action: {
                    if let url = URL(string: article.link) {
                        selectedURL = url
                    }
                }) {
                    VStack(alignment: .leading, spacing: 4) {
                        if let date = article.pubDate {
                            Text(dateFormatted(date))
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
                    }
                    .padding(.vertical, 8)
                }
                Divider().padding(.vertical, 4)
            }
        }
    }

    private func dateFormatted(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "M월 d일"
        return formatter.string(from: date)
    }
}

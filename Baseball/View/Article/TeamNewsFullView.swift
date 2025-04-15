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
    @State private var searchText: String = ""
    @State private var isSearching: Bool = false

    var filteredArticles: [Article] {
        if searchText.isEmpty {
            return viewModel.articles
        } else {
            return viewModel.articles.filter { $0.title.localizedCaseInsensitiveContains(searchText) }
        }
    }

    var body: some View {
        ScrollView {
            if viewModel.isLoading {
                loadingView()
            } else {
                if isSearching {
                    searchField()
                }
                articleListView()
            }
        }
        .navigationTitle("\(teamName) 뉴스")
        .toolbar { toolbarView() }
        .sheet(item: $selectedURL) { url in
            SafariView(url: url)
        }
        .onAppear {
            viewModel.fetch(for: teamName)
        }
    }

    // MARK: - 로딩 뷰
    func loadingView() -> some View {
        ProgressView("로딩 중...")
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.top, 60)
    }

    // MARK: - 검색 필드
    func searchField() -> some View {
        HStack {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)

                TextField("검색어를 입력하세요", text: $searchText)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                    .foregroundColor(.primary)

                if !searchText.isEmpty {
                    Button(action: {
                        self.searchText = ""
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                    }
                }
            }
            .padding(10)
            .background(Color(.systemGray6))
            .cornerRadius(10)
            .padding(.horizontal)
            .transition(.move(edge: .top).combined(with: .opacity))
            .animation(.easeInOut(duration: 0.3), value: isSearching)
        }
        .padding(.top, 8)
    }


    // MARK: - 기사 리스트
    func articleListView() -> some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(filteredArticles) { article in
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
        .padding(.horizontal)
        .padding(.top, 12)
    }

    // MARK: - 툴바
    func toolbarView() -> some ToolbarContent {
        ToolbarItem(placement: .navigationBarTrailing) {
            Button(action: {
                withAnimation {
                    isSearching.toggle()
                    if !isSearching {
                        searchText = ""
                    }
                }
            }) {
                Image(systemName: isSearching ? "xmark" : "magnifyingglass")
                    .foregroundColor(.black)
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


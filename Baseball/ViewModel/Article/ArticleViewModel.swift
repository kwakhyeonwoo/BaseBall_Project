//
//  ArticleViewModel.swift
//     
//
//  Created by 곽현우 on 3/25/25.
//

import Foundation
import FeedKit
import SwiftUI

class TeamNewsManager: ObservableObject {
    @Published var articles: [Article] = []
    @Published var highlights: [HighlightVideo] = []

    private let newsFetcher = NewsFetcher()
    private let videoArticleModel = VideoArticleViewModel()

    func fetchContent(for team: String) {
        newsFetcher.fetchNews(for: team) { articles in
            DispatchQueue.main.async {
                self.articles = articles
            }
        }

        videoArticleModel.fetchHighlights(for: team) { videos in
            DispatchQueue.main.async {
                self.highlights = videos
            }
        }
    }
}

class NewsFetcher {
    func fetchNews(for team: String, completion: @escaping ([Article]) -> Void) {
        let query = "\(team) 야구"
        let encoded = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let urlStr = "https://news.google.com/rss/search?q=\(encoded)&hl=ko&gl=KR&ceid=KR:ko"

        guard let url = URL(string: urlStr) else {
            completion([])
            return
        }

        let parser = FeedParser(URL: url)
        parser.parseAsync { result in
            switch result {
            case .success(let feed):
                let articles: [Article] = feed.rssFeed?.items?.compactMap { item in
                    guard let title = item.title, let link = item.link else { return nil }
                    return Article(title: title, link: link)
                } ?? []
                completion(articles)
            case .failure:
                completion([])
            }
        }
    }
}

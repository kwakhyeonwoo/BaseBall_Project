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

    func fetchContent(for team: String) {
        newsFetcher.fetchNews(for: team) { articles in
            DispatchQueue.main.async {
                self.articles = articles
            }
        }

        let encodedTeam = team.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
            guard let url = URL(string: "http://192.119.129.160:3000/api/highlights/\(encodedTeam)") else { return }

            URLSession.shared.dataTask(with: url) { data, _, error in
                guard let data = data, error == nil else { return }

                do {
                    let videos = try JSONDecoder().decode([HighlightVideo].self, from: data)
                    DispatchQueue.main.async {
                        self.highlights = videos
                    }
                } catch {
                    print("❌ 하이라이트 JSON 파싱 실패: \(error)")
                    print(String(data: data, encoding: .utf8) ?? "no data")
                }
            }.resume()
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
                    guard let originalTitle = item.title,
                          let link = item.link else { return nil }

                    let pubDate = item.pubDate
                    let source = item.source?.value

                    // ✅ title에서 가장 마지막 " - " 기준으로 앞부분만 사용
                    let components = originalTitle.components(separatedBy: " - ")
                    let cleanTitle = components.dropLast().joined(separator: " - ")

                    return Article(title: cleanTitle, link: link, pubDate: pubDate, source: source)
                } ?? []
                completion(articles)
                
            case .failure:
                completion([])
            }
        }
    }
}

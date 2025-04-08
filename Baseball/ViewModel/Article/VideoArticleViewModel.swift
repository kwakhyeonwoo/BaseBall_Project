//
//  VideoArticleViewModel.swift
//     
//
//  Created by 곽현우 on 3/26/25.
//

import Foundation
import FeedKit

class HighlightVideoFetcher: ObservableObject {
    @Published var highlightVideos: [HighlightVideo] = []
    
    //Google 뉴스 크롤링 
    func fetchHighlights() {
        guard let url = URL(string: "https://news.google.com/rss/search?q=SSG+하이라이트+야구&hl=ko&gl=KR&ceid=KR:ko") else { return }

        let parser = FeedParser(URL: url)

        parser.parseAsync { result in
            switch result {
            case .success(let feed):
                if let items = feed.rssFeed?.items {
                    DispatchQueue.main.async {
                        self.highlightVideos = items.compactMap { item -> HighlightVideo? in
                            guard let title = item.title, let link = item.link else { return nil }

                            return HighlightVideo(
                                title: title,
                                thumbnailURL: "https://i.ytimg.com/vi/default/hqdefault.jpg", // 🔄 썸네일이 없는 경우 기본값
                                videoURL: link
                            )
                        }
                    }
                }
            case .failure(let error):
                print("❌ 하이라이트 파싱 실패: \(error)")
            }
        }
    }
}

//MARK: 유튜브 영상 파싱
class VideoArticleViewModel: ObservableObject {
    @Published var cachedVideos: [HighlightVideo] = []

    private var nextPageToken: String? = nil
    private var isFetching = false

    private let cacheKey = "cachedHighlights"
    private let timestampKey = "lastFetchTimestamp"
    private let cacheDuration: TimeInterval = 600 // 10분

    func fetchHighlights(for team: String, append: Bool = false, completion: @escaping ([HighlightVideo]) -> Void) {
        // ✅ append 아닐 때만 캐시 확인
        if !append, let cached = loadCache(for: team), !isCacheExpired(for: team) {
            print("✅ [Cache Hit] 캐시된 \(team) 영상 사용")
            self.cachedVideos = cached
            completion(cached)
            return
        }

        guard !isFetching else { return }
        isFetching = true

        let apiKey = "AIzaSyBQLvRIl6NrIhtgArmqC8twA4mE-pRSgaI"
        let query = "\(team)"
        let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""

        var urlString = "https://www.googleapis.com/youtube/v3/search?part=snippet&q=\(encodedQuery)&type=video&order=date&maxResults=50&key=\(apiKey)"
        if let token = nextPageToken {
            urlString += "&pageToken=\(token)" // ✅ 새 페이지 요청
        }

        guard let url = URL(string: urlString) else {
            isFetching = false
            completion([])
            return
        }

        URLSession.shared.dataTask(with: url) { data, _, _ in
            defer { self.isFetching = false }

            guard let data = data else {
                completion([])
                return
            }

            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let items = json["items"] as? [[String: Any]] {

                    self.nextPageToken = json["nextPageToken"] as? String // ✅ 항상 업데이트

                    let newVideos = items.compactMap { item -> HighlightVideo? in
                        guard
                            let id = item["id"] as? [String: Any],
                            let videoId = id["videoId"] as? String,
                            let snippet = item["snippet"] as? [String: Any],
                            let title = snippet["title"] as? String,
                            let thumbnails = snippet["thumbnails"] as? [String: Any],
                            let highThumb = thumbnails["high"] as? [String: Any],
                            let thumbnailURL = highThumb["url"] as? String
                        else { return nil }

                        return HighlightVideo(title: title, thumbnailURL: thumbnailURL, videoURL: "https://www.youtube.com/watch?v=\(videoId)")
                    }

                    DispatchQueue.main.async {
                        if append {
                            self.cachedVideos.append(contentsOf: newVideos)
                            completion(newVideos)
                        } else {
                            self.cachedVideos = newVideos
                            self.saveCache(newVideos, for: team)
                            self.updateTimestamp(for: team)
                            completion(newVideos)
                        }
                    }

                } else {
                    completion([])
                }
            } catch {
                completion([])
            }
        }.resume()
    }


    // MARK: - Caching Helpers
    private func saveCache(_ videos: [HighlightVideo], for team: String) {
        if let encoded = try? JSONEncoder().encode(videos) {
            UserDefaults.standard.set(encoded, forKey: cacheKey(for: team))
        }
    }

    private func loadCache(for team: String) -> [HighlightVideo]? {
        if let data = UserDefaults.standard.data(forKey: cacheKey(for: team)),
           let decoded = try? JSONDecoder().decode([HighlightVideo].self, from: data) {
            return decoded
        }
        return nil
    }

    private func updateTimestamp(for team: String) {
        UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: timestampKey(for: team))
    }

    private func isCacheExpired(for team: String) -> Bool {
        let last = UserDefaults.standard.double(forKey: timestampKey(for: team))
        let now = Date().timeIntervalSince1970
        return (now - last) > cacheDuration
    }
    
    private func cacheKey(for team: String) -> String {
        return "cachedHighlights_\(team)"
    }

    private func timestampKey(for team: String) -> String {
        return "lastFetchTimestamp_\(team)"
    }

    func resetPagination() {
        nextPageToken = nil
    }
}

//AIzaSyBQLvRIl6NrIhtgArmqC8twA4mE-pRSgaI,VideoArticleViewModel

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

                            let videoId = URLComponents(string: link)?
                                .queryItems?
                                .first(where: { $0.name == "v" })?
                                .value ?? UUID().uuidString
                            
                            return HighlightVideo(
                                videoId: videoId,
                                title: title,
                                thumbnailURL: "https://i.ytimg.com/vi/\(videoId)/hqdefault.jpg",
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
    private let cacheDuration: TimeInterval = 600 // 10분

    func fetchHighlights(for team: String, append: Bool = false, completion: @escaping ([HighlightVideo]) -> Void) {
            guard !isFetching else { return }
            isFetching = true
            let startTime = Date()
        
            let encodedTeam = team.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
            guard let url = URL(string: "http://192.119.129.52:3000/api/highlights/\(encodedTeam.trimmingCharacters(in: CharacterSet(charactersIn: "/")))") else {
                isFetching = false
                completion([])
                return
            }

            URLSession.shared.dataTask(with: url) { data, _, error in
                defer {
                    self.isFetching = false
                    let elapsed = Date().timeIntervalSince(startTime)
                    print("⏱️ API 응답 시간: \(elapsed)초")
                }

                guard let data = data, error == nil else {
                    completion([])
                    return
                }

                do {
                    let videos = try JSONDecoder().decode([HighlightVideo].self, from: data)

                    // ✅ 중복 제거
                    let uniqueVideos = videos.filter { new in
                        !self.cachedVideos.contains(where: { $0.videoId == new.videoId })
                    }

                    DispatchQueue.main.async {
                        if append {
                            self.cachedVideos.append(contentsOf: uniqueVideos)
                            completion(uniqueVideos)
                        } else {
                            self.cachedVideos = uniqueVideos
                            completion(uniqueVideos)
                        }
                    }
                } catch {
                    print("❌ JSON 디코딩 실패: \(error)")
                    completion([])
                }
            }.resume()
        }

        func resetPagination() {
            // 프록시 서버 기반이므로 페이징은 불필요하거나 서버 구현 필요
            cachedVideos = []
        }
}


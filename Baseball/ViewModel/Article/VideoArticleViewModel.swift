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

            let encodedTeam = team.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
            guard let url = URL(string: "http://192.210.221.177:3000/api/highlights/\(encodedTeam)") else {
                isFetching = false
                completion([])
                return
            }

            URLSession.shared.dataTask(with: url) { data, _, error in
                defer { self.isFetching = false }

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
//    func fetchHighlights(for team: String, append: Bool = false, completion: @escaping ([HighlightVideo]) -> Void) {
//
//        guard !isFetching else { return }
//        isFetching = true
//
//        let apiKey = "AIzaSyBQLvRIl6NrIhtgArmqC8twA4mE-pRSgaI"
//        let query = "\(team) 야구"
//        let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
//
//        var urlString = "https://www.googleapis.com/youtube/v3/search?part=snippet&q=\(encodedQuery)&type=video&order=date&maxResults=50&key=\(apiKey)"
//        if let token = nextPageToken {
//            urlString += "&pageToken=\(token)" // ✅ 새 페이지 요청
//        }
//
//        guard let url = URL(string: urlString) else {
//            isFetching = false
//            completion([])
//            return
//        }
//
//        URLSession.shared.dataTask(with: url) { data, _, _ in
//            defer { self.isFetching = false }
//
//            guard let data = data else {
//                completion([])
//                return
//            }
//
//            do {
//                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
//                   let items = json["items"] as? [[String: Any]] {
//
//                    self.nextPageToken = json["nextPageToken"] as? String
//
//                    let newVideos = items.compactMap { item -> HighlightVideo? in
//                        guard
//                            let id = item["id"] as? [String: Any],
//                            let videoId = id["videoId"] as? String,
//                            let snippet = item["snippet"] as? [String: Any],
//                            let title = snippet["title"] as? String,
//                            let thumbnails = snippet["thumbnails"] as? [String: Any],
//                            let highThumb = thumbnails["high"] as? [String: Any],
//                            let thumbnailURL = highThumb["url"] as? String
//                        else { return nil }
//
//                        return HighlightVideo(
//                            videoId: videoId,
//                            title: title,
//                            thumbnailURL: thumbnailURL,
//                            videoURL: "https://www.youtube.com/watch?v=\(videoId)")
//                    }
//                    
//                    //MARK: 중복 제거
//                    let uniqueVideos = newVideos.filter { new in
//                        !self.cachedVideos.contains(where: { $0.videoId == new.videoId })
//                    }
//
//                    DispatchQueue.main.async {
//                        if append {
//                            self.cachedVideos.append(contentsOf: uniqueVideos)
//                            completion(uniqueVideos)
//                        } else {
//                            self.cachedVideos = uniqueVideos
//                            completion(uniqueVideos)
//                        }
//                    }
//                } else {
//                    completion([])
//                }
//            } catch {
//                completion([])
//            }
//        }.resume()
//    }

//    func resetPagination() {
//        nextPageToken = nil
//    }
}

//AIzaSyBQLvRIl6NrIhtgArmqC8twA4mE-pRSgaI,VideoArticleViewModel

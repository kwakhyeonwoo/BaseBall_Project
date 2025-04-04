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
    func fetchHighlights(for team: String, completion: @escaping ([HighlightVideo]) -> Void) {
        let apiKey = "AIzaSyBQLvRIl6NrIhtgArmqC8twA4mE-pRSgaI"
        let query = "\(team) 야구"
        let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let urlString = "https://www.googleapis.com/youtube/v3/search?part=snippet&q=\(encodedQuery)&type=video&order=date&maxResults=15&key=\(apiKey)"

        guard let url = URL(string: urlString) else {
            completion([])
            return
        }

        URLSession.shared.dataTask(with: url) { data, _, _ in
            guard let data = data else {
                completion([])
                return
            }

            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let items = json["items"] as? [[String: Any]] {

                    let videos = items.compactMap { item -> HighlightVideo? in
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

                    completion(videos)
                }
            } catch {
                completion([])
            }
        }.resume()
    }
}

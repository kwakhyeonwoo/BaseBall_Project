//
//  VideoArticleModel.swift
//     
//
//  Created by 곽현우 on 3/26/25.
//

import Foundation

struct HighlightVideo: Identifiable {
    let id = UUID()
    let title: String
    let thumbnailURL: String
    let videoURL: String
}

class YouTubeFetcher: ObservableObject {
    func fetchHighlights(for team: String, completion: @escaping ([HighlightVideo]) -> Void) {
        let apiKey = "AIzaSyBQLvRIl6NrIhtgArmqC8twA4mE-pRSgaI"
        let query = "\(team) 야구 하이라이트"
        let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let urlString = "https://www.googleapis.com/youtube/v3/search?part=snippet&q=\(encodedQuery)&type=video&maxResults=9&key=\(apiKey)"

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

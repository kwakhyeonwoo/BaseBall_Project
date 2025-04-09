//
//  TeamNewsFullViewModel.swift
//     
//
//  Created by 곽현우 on 4/9/25.
//

import Foundation

class TeamNewsFullViewModel: ObservableObject {
    @Published var articles: [Article] = []
    @Published var isLoading = false

    func fetch(for team: String) {
        isLoading = true
        NewsFetcher().fetchNews(for: team) { result in
            DispatchQueue.main.async {
                self.articles = result.sorted {
                    ($0.pubDate ?? Date.distantPast) > ($1.pubDate ?? Date.distantPast)
                }
                self.isLoading = false
            }
        }
    }
}


//
//  TeamNewsFullViewModel.swift
//     
//
//  Created by 곽현우 on 4/9/25.
//

import Foundation
import Combine

class TeamNewsFullViewModel: ObservableObject {
    @Published var articles: [Article] = []
    @Published var isLoading: Bool = false
    @Published var searchText: String = ""
    @Published var filteredArticles: [Article] = []

    private var cancellables = Set<AnyCancellable>()

    init() {
        $searchText
            //디바운스를 통해 마지막 이벤트만 실행
            .debounce(for: .milliseconds(500), scheduler: RunLoop.main)
            .removeDuplicates()
            .sink { [weak self] query in
                guard let self = self else { return }
                if query.isEmpty {
                    self.filteredArticles = self.articles
                } else {
                    self.filteredArticles = self.articles.filter {
                        $0.title.localizedCaseInsensitiveContains(query)
                    }
                }
            }
            .store(in: &cancellables)
    }

    func fetch(for team: String) {
        isLoading = true
        NewsFetcher().fetchNews(for: team) { result in
            DispatchQueue.main.async {
                let sorted = result.sorted {
                    ($0.pubDate ?? Date.distantPast) > ($1.pubDate ?? Date.distantPast)
                }
                self.articles = sorted
                self.filteredArticles = sorted
                self.isLoading = false
            }
        }
    }
}


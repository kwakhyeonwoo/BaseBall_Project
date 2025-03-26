//
//  TeamArticle.swift
//     
//
//  Created by 곽현우 on 3/25/25.
//

//import SwiftUI
//
//struct SSGNewsListView: View {
//    @State private var articles: [NewsArticle] = []
//
//    var body: some View {
//        List(articles) { article in
//            VStack(alignment: .leading, spacing: 6) {
//                Text(article.title)
//                    .font(.headline)
//                Text(article.date)
//                    .font(.caption)
//                    .foregroundColor(.gray)
//                Link("기사 보기", destination: URL(string: article.url)!)
//                    .font(.caption)
//                    .foregroundColor(.blue)
//            }
//            .padding(.vertical, 5)
//        }
//        .onAppear {
//            SSGNewsCrawler().fetchSSGNews { fetchedArticles in
//                DispatchQueue.main.async {
//                    self.articles = fetchedArticles
//                }
//            }
//        }
//    }
//}


//#Preview {
//    TeamArticle()
//}

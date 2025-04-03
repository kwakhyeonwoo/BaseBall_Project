//
//  TeamArticle.swift
//     
//
//  Created by 곽현우 on 3/25/25.
//

import SwiftUI

struct TeamNewsFullView: View {
    let teamName: String
    let articles: [Article]

    @State private var selectedURL: URL?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                ForEach(articles) { article in
                    Button(action: {
                        if let url = URL(string: article.link) {
                            selectedURL = url
                        }
                    }) {
                        Text(article.title)
                            .font(.body)
                            .foregroundColor(.black)
                            .multilineTextAlignment(.leading)
                    }
                    Divider()
                }
            }
            .padding()
        }
        .navigationTitle("\(teamName) 뉴스")
        .sheet(item: $selectedURL) { url in
            SafariView(url: url)
        }
    }
}

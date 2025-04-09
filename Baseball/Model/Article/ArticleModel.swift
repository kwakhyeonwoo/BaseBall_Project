//
//  ArticleModel.swift
//     
//
//  Created by 곽현우 on 3/25/25.
//

import Foundation

struct Article: Identifiable {
    let id = UUID()
    let title: String
    let link: String
    let pubDate: Date?
    let source: String?
    
    init(title: String, link: String, pubDate: Date? = nil, source: String? = nil) {
        self.title = title
        self.link = link
        self.pubDate = pubDate
        self.source = source
    }
}

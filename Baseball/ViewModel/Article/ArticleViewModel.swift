//
//  ArticleViewModel.swift
//     
//
//  Created by 곽현우 on 3/25/25.
//

import Foundation
import SwiftSoup
import UIKit

class SSGNewsCrawler: ObservableObject {
    @Published var ssgArticles: [Article] = []
    
    func fetchSSGNews() {
        guard let url = URL(string: "https://news.google.com/rss/search?q=SSG+야구+프로야구&hl=ko&gl=KR&ceid=KR:ko") else { return }

        URLSession.shared.dataTask(with: url) { data, _, error in
            guard let data = data, error == nil else { return }

            let parser = XMLParser(data: data)
            let rssParser = RSSParser()

            parser.delegate = rssParser

            if parser.parse() {
                DispatchQueue.main.async {
                    self.ssgArticles = rssParser.articles
                }
            } else {
                print("❌ RSS 파싱 실패")
            }
        }.resume()
    }

    func openInSafari(urlString: String) {
        if let url = URL(string: urlString) {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
    }
}

class RSSParser: NSObject, XMLParserDelegate {
    var articles: [Article] = []
    private var currentElement = ""
    private var currentTitle = ""
    private var currentLink = ""

    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?,
                qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
        currentElement = elementName
    }

    func parser(_ parser: XMLParser, foundCharacters string: String) {
        switch currentElement {
        case "title":
            currentTitle += string
        case "link":
            currentLink += string
        default:
            break
        }
    }

    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?,
                qualifiedName qName: String?) {
        if elementName == "item" {
            let cleanTitle = currentTitle.trimmingCharacters(in: .whitespacesAndNewlines)
            let cleanLink = currentLink.trimmingCharacters(in: .whitespacesAndNewlines)
            if cleanTitle.contains("SSG") {
                articles.append(Article(title: cleanTitle, link: cleanLink))
            }
            currentTitle = ""
            currentLink = ""
        }
    }
}

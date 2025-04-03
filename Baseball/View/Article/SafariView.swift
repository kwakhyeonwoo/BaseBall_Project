//
//  SafariView.swift
//     
//
//  Created by 곽현우 on 4/3/25.
//

import SwiftUI
import SafariServices

struct SafariView: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> SFSafariViewController {
        return SFSafariViewController(url: url)
    }

    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {}
}

extension URL: Identifiable {
    public var id: String { absoluteString }
}

//#Preview {
//    SafariView()
//}

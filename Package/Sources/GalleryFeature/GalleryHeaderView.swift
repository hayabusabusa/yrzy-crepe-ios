//
//  GalleryHeaderView.swift
//
//
//  Created by Shunya Yamada on 2024/01/11.
//

import NukeUI
import SwiftUI

struct GalleryHeaderView: View {
    var pageViewConfigurations: [PageView.Configuration]

    var body: some View {
        TabView {
            ForEach(pageViewConfigurations) { configuration in
                PageView(configuration: configuration)
            }
        }
        .tabViewStyle(PageTabViewStyle())
        .frame(height: 280)
    }
}

extension GalleryHeaderView {
    struct PageView: View {
        var configuration: Configuration

        var body: some View {
            LazyImage(url: configuration.imageURL.flatMap { URL(string: $0) }) { state in
                if let image = state.image {
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } else {
                    Color(.secondarySystemBackground)
                }
            }
            .clipped()
        }
    }
}

extension GalleryHeaderView.PageView {
    struct Configuration: Identifiable, Hashable {
        let id: String?
        let title: String
        let imageURL: String?
    }
}

#if DEBUG
#Preview {
    GalleryHeaderView(
        pageViewConfigurations: [
            .init(
                id: UUID().uuidString,
                title: "TEST1",
                imageURL: "https://avatars.githubusercontent.com/u/31949692?v=4"
            ),
            .init(
                id: UUID().uuidString, 
                title: "TEST2",
                imageURL: "https://avatars.githubusercontent.com/u/31949692?v=4"
            )
        ]
    )
}
#endif

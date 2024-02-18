//
//  BookshelfItemView.swift
//
//
//  Created by Shunya Yamada on 2024/02/18.
//

import NukeUI
import SwiftUI

struct BookshelfItemView: View {
    struct Configuration: Hashable {
        let title: String
        let imageURL: String?
        let createdAt: String?
    }

    let configuration: Configuration

    var body: some View {
        VStack(spacing: 0) {
            LazyImage(url: configuration.imageURL.flatMap { URL(string: $0) }) { state in
                if let image = state.image {
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } else {
                    Color(.secondarySystemBackground)
                }
            }
            .frame(height: 220)
            .clipped()

            Text(configuration.title)
                .font(.callout)
                .bold()
                .lineLimit(3)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(12)
        }
    }
}

#if DEBUG
#Preview {
    BookshelfItemView(
        configuration: BookshelfItemView.Configuration(
            title: "タイトル",
            imageURL: nil,
            createdAt: nil
        )
    )
}
#endif

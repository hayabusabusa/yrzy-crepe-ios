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
        let createdAt: String
    }

    let configuration: Configuration
    var action: (() -> Void)?

    var body: some View {
        Button {
            action?()
        } label: {
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

                VStack(alignment: .leading, spacing: 2) {
                    Text(configuration.title)
                        .font(.callout)
                        .bold()
                        .lineLimit(3)
                        .multilineTextAlignment(.leading)
                    
                    Text(configuration.createdAt)
                        .font(.caption)
                        .foregroundStyle(Color(.lightGray))

                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(12)
            }
        }
        .foregroundStyle(
            Color(uiColor: .label)
        )
    }
}

#if DEBUG
#Preview {
    BookshelfItemView(
        configuration: BookshelfItemView.Configuration(
            title: "タイトル",
            imageURL: nil,
            createdAt: "2024/02/18 12:00"
        ),
        action: nil
    )
}
#endif

//
//  GallerySectionView.swift
//
//
//  Created by Shunya Yamada on 2024/01/12.
//

import NukeUI
import SwiftUI

struct GallerySectionView: View {
    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]

    var configurations: [ItemView.Configuration]

    var body: some View {
        LazyVGrid(columns: columns, spacing: 8) {
            ForEach(configurations) { configuration in
                ItemView(configuration: configuration)
            }
        }
        .padding([.trailing, .leading], 8)
    }
}

extension GallerySectionView {
    struct ItemView: View {
        var configuration: Configuration

        var body: some View {
            Button(action: {

            }, label: {
                VStack {
                    LazyImage(url: configuration.imageURL.flatMap { URL(string: $0) }) { state in
                        if let image = state.image {
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        } else {
                            Color(.secondarySystemBackground)
                        }
                    }
                    .frame(height: 120)
                    .clipped()

                    Text(configuration.title)
                        .bold()
                        .lineLimit(2)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(EdgeInsets(top: 2, leading: 4, bottom: 2, trailing: 4))
                }
            })
            .foregroundStyle(
                Color(uiColor: .label)
            )
        }
    }
}

extension GallerySectionView.ItemView {
    struct Configuration: Identifiable, Hashable {
        let id: String?
        let title: String
        let imageURL: String?
    }
}

#if DEBUG
#Preview {
    GallerySectionView(
        configurations: [
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

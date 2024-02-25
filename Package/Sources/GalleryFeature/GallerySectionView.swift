//
//  GallerySectionView.swift
//
//
//  Created by Shunya Yamada on 2024/01/12.
//

import NukeUI
import SharedViews
import SwiftUI

struct GallerySectionView: View {
    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]

    var configurations: [ItemView.Configuration]
    var action: ((Int) -> Void)?

    var body: some View {
        LazyVGrid(columns: columns, spacing: 8) {
            ForEach(Array(configurations.enumerated()), id: \.offset) { index, configuration in
                ItemView(configuration: configuration) {
                    action?(index)
                }
            }
        }
        .padding([.trailing, .leading], 16)
    }
}

extension GallerySectionView {
    struct ItemView: View {
        var configuration: Configuration
        var action: (() -> Void)?

        var body: some View {
            Button(action: {
                action?()
            }, label: {
                VStack {
                    LazyImage(url: configuration.imageURL.flatMap { URL(string: $0) }) { state in
                        if let image = state.image {
                            AdjustedRatioImage(
                                image: image,
                                uiImage: state.imageContainer?.image
                            )
                        } else {
                            Color(.secondarySystemBackground)
                        }
                    }
                    .frame(height: 108)
                    .clipped()

                    Text(configuration.title)
                        .font(.callout)
                        .bold()
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(EdgeInsets(top: 2, leading: 0, bottom: 2, trailing: 0))

                    Spacer()
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
                title: "奥さんは最初世の中を見る彼の口にした。",
                imageURL: "https://avatars.githubusercontent.com/u/31949692?v=4"
            ),
            .init(
                id: UUID().uuidString,
                title: "言葉を継ぎ足した。",
                imageURL: "https://avatars.githubusercontent.com/u/31949692?v=4"
            )
        ]
    )
}
#endif

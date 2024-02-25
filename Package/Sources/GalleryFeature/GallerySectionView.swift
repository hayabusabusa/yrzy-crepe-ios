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

    var title: String
    var moreButtonTitle: String
    var configurations: [ItemView.Configuration]
    var action: ((Int) -> Void)?
    var moreAction: (() -> Void)?

    var body: some View {
        VStack(spacing: 24) {
            Text(title)
                .font(.title3)
                .bold()
                .frame(maxWidth: .infinity, alignment: .leading)

            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(Array(configurations.enumerated()), id: \.offset) { index, configuration in
                    ItemView(configuration: configuration) {
                        action?(index)
                    }
                }
            }

            Rectangle()
                .frame(height: 1)
                .foregroundStyle(Color(.systemGray5))

            Button(action: {
                moreAction?()
            }, label: {
                HStack(spacing: 4) {
                    Text(moreButtonTitle)
                        .font(.caption)

                    Image(systemName: "chevron.right")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 12, height: 12)

                    Spacer()
                }
            })
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(EdgeInsets(top: 32, leading: 16, bottom: 28, trailing: 16))
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
        title: "最近追加された作品",
        moreButtonTitle: "もっとみる",
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

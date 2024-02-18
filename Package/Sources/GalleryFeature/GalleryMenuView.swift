//
//  GalleryMenuView.swift
//
//
//  Created by Shunya Yamada on 2024/02/18.
//

import SwiftUI

struct GalleryMenuView: View {
    var searchAction: (() -> Void)?
    var scrapingAction: (() -> Void)?
    var favoriteAction: (() -> Void)?

    var body: some View {
        HStack {
            Spacer()

            ItemView(
                imageName: "magnifyingglass",
                text: "検索"
            ) {
                searchAction?()
            }
            .disabled(true)

            Spacer()

            ItemView(
                imageName: "doc.fill.badge.plus",
                text: "スクレイピング"
            ) {
                scrapingAction?()
            }
            .disabled(true)

            Spacer()

            ItemView(
                imageName: "star.fill",
                text: "お気に入り"
            ) {
                favoriteAction?()
            }

            Spacer()
        }
        .padding(8)
    }
}

extension GalleryMenuView {
    struct ItemView: View {
        var imageName: String
        var text: String
        var action: (() -> Void)?

        var body: some View {
            Button {
                action?()
            } label: {
                VStack {
                    ZStack {
                        Circle()
                            .frame(width: 40, height: 40)
                            .foregroundStyle(Color(.secondarySystemBackground))

                        Image(systemName: imageName)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 16, height: 16)
                    }

                    Text(text)
                        .bold()
                        .font(.caption)
                }
            }
            .frame(width: 80)
        }
    }
}

#if DEBUG
#Preview {
    GalleryMenuView()
}
#endif

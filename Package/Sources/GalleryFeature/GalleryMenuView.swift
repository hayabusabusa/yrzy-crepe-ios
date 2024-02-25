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
        ScrollView(.horizontal) {
            HStack {
                ItemView(
                    imageName: "magnifyingglass",
                    text: "検索", 
                    color: .systemMint
                ) {
                    searchAction?()
                }

                Spacer()

                ItemView(
                    imageName: "heart",
                    text: "お気に入り",
                    color: .systemPink
                ) {
                    favoriteAction?()
                }

                Spacer()

                ItemView(
                    imageName: "doc",
                    text: "スクレイピング",
                    color: .systemPurple
                ) {
                    scrapingAction?()
                }

                Spacer()
            }
            .padding(EdgeInsets(top: 16, leading: 8, bottom: 16, trailing: 8))
        }
        .scrollIndicators(.hidden)
    }
}

extension GalleryMenuView {
    struct ItemView: View {
        var imageName: String
        var text: String
        var color: UIColor
        var action: (() -> Void)?

        private let size = CGSize(width: 140, height: 60)

        var body: some View {
            Button {
                action?()
            } label: {
                ZStack {
                    RoundedRectangle(cornerSize: CGSize(width: 4, height: 4))
                        .foregroundStyle(Color(color))

                    Text(text)
                        .font(.caption)
                        .bold()
                        .foregroundStyle(Color(.white))

                    Image(systemName: imageName)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 72, height: 72)
                        .position(x: size.width / 6, y: size.height - 16)
                        .foregroundStyle(
                            Color(.white)
                                .opacity(0.3)
                        )
                }
                .clipped()
            }
            .frame(width: size.width, height: size.height)
        }
    }
}

#if DEBUG
#Preview {
    GalleryMenuView()
}
#endif

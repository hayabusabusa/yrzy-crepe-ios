//
//  FavoritesItemView.swift
//
//
//  Created by Shunya Yamada on 2024/02/25.
//

import NukeUI
import SwiftUI

struct FavoritesItemView: View {
    var configuration: Configuration
    var action: (() -> Void)?

    var body: some View {
        Button(action: {
            action?()
        }, label: {
            HStack {
                LazyImage(url: configuration.imageURL.flatMap { URL(string: $0) }) { state in
                    if let image = state.image {
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } else {
                        Color(.secondarySystemBackground)
                    }
                }
                .frame(width: 100, height: 80)
                .clipShape(
                    RoundedRectangle(
                        cornerSize: CGSize(
                            width: 8,
                            height: 8
                        )
                    )
                )

                VStack(alignment: .leading) {
                    Text(configuration.title)
                        .bold()
                        .lineLimit(3)
                        .multilineTextAlignment(.leading)
                        .foregroundStyle(Color(.label))

                    if let date = configuration.date {
                        Text(date)
                            .font(.caption)
                            .foregroundStyle(Color(.systemGray))
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Image(systemName: "chevron.right")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 16, height: 16)
                    .foregroundStyle(Color(.systemGray4))
            }
        })
        .padding([.leading, .trailing], 16)
    }
}

extension FavoritesItemView {
    struct Configuration: Hashable {
        var title: String
        var date: String?
        var imageURL: String?
    }
}

#if DEBUG
#Preview {
    FavoritesItemView(
        configuration: FavoritesItemView.Configuration(
            title: "発破だよカムパネルラが向こう岸の、三つならんでいるからきっとそうだわはなしてごらん。",
            date: "2024/02/25",
            imageURL: "https://avatars.githubusercontent.com/u/31949692?v=4"
        )
    )
}
#endif

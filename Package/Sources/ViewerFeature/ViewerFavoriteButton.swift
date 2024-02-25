//
//  ViewerFavoriteButton.swift
//
//
//  Created by Shunya Yamada on 2024/02/22.
//

import SwiftUI

struct ViewerFavoriteButton: View {
    var isFavorite: Bool
    var action: (() -> Void)?

    var body: some View {
        Button(action: {
            action?()
        }, label: {
            Image(systemName: isFavorite ? "heart.fill" : "heart")
                .frame(width: 24, height: 24)
        })
    }
}

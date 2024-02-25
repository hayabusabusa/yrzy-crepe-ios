//
//  ViewerPageView.swift
//
//
//  Created by Shunya Yamada on 2024/02/18.
//

import NukeUI
import SharedViews
import SwiftUI

struct ViewerPageView: View {
    struct Configuration: Identifiable, Hashable {
        let id: String
        let imageURL: URL
    }
    
    var configuration: Configuration

    var body: some View {
        LazyImage(url: configuration.imageURL) { state in
            if let image = state.image {
                AdjustedRatioImage(
                    image: image,
                    uiImage: state.imageContainer?.image
                )
            } else {
                Color(.secondarySystemBackground)
            }
        }
    }
}

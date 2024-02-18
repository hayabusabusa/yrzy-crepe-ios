//
//  File.swift
//  
//
//  Created by Shunya Yamada on 2024/02/18.
//

import NukeUI
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
                isImageHorizontal(state.imageContainer?.image)
                    ? image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                    : image
                        .resizable()
                        .aspectRatio(contentMode: .fill)

            } else {
                Color(.secondarySystemBackground)
            }
        }
    }
}

private extension ViewerPageView {
    /// 画像が横長かどうか返す.
    ///
    /// `Image` を `.aspectRatio(contentMode: .fit)` で表示すると縦長画像に不要な余白ができてしまうので
    /// 画像の比率に応じて `.aspectRatio(contentMode:)` に渡す表示モードを変える.
    ///
    /// - Parameter image: 表示しようとしている `UIImage`.
    /// - Returns: 横長かどうか.
    func isImageHorizontal(_ image: UIImage?) -> Bool {
        guard let image else {
            return false
        }
        return image.size.width >= image.size.height
    }
}

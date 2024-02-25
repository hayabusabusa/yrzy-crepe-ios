//
//  AdjustedRatioImage.swift
//
//
//  Created by Shunya Yamada on 2024/02/25.
//

import SwiftUI

/// 縦横比率に応じて表示を切り替える `Image`.
///
/// Nuke で取得した画像表示用の View.
public struct AdjustedRatioImage: View {
    var image: Image
    var uiImage: UIImage?

    public var body: some View {
        isImageHorizontal(uiImage)
            ? image
                .resizable()
                .aspectRatio(contentMode: .fit)
            : image
                .resizable()
                .aspectRatio(contentMode: .fill)
    }

    public init(
        image: Image,
        uiImage: UIImage? = nil
    ) {
        self.image = image
        self.uiImage = uiImage
    }
}

private extension AdjustedRatioImage {
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

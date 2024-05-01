//
//  LargeThumbnailView.swift
//
//
//  Created by Shunya Yamada on 2024/04/20.
//

import NukeUI
import SwiftUI

/// 大きめのサムネイルと一緒に作品情報を表示する際に利用する View.
public struct LargeThumbnailView: View {
    /// 設定項目.
    public struct Configuration: Hashable {
        public let title: String
        public let imageURL: String?
        public let createdAt: String

        public init(
            title: String,
            imageURL: String?,
            createdAt: String
        ) {
            self.title = title
            self.imageURL = imageURL
            self.createdAt = createdAt
        }
    }

    public var configuration: Configuration
    public var action: (() -> Void)?

    public var body: some View {
        Button {
            action?()
        } label: {
            VStack(spacing: 0) {
                LazyImage(url: configuration.imageURL.flatMap { URL(string: $0) }) { state in
                    if let image = state.image {
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } else {
                        Color(.secondarySystemBackground)
                    }
                }
                .frame(height: 220)
                .clipped()

                VStack(alignment: .leading, spacing: 2) {
                    Text(configuration.title)
                        .font(.callout)
                        .bold()
                        .lineLimit(3)
                        .multilineTextAlignment(.leading)

                    Text(configuration.createdAt)
                        .font(.caption)
                        .foregroundStyle(Color(.lightGray))

                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(12)
            }
        }
        .foregroundStyle(
            Color(uiColor: .label)
        )
    }

    public init(
        configuration: Configuration,
        action: (() -> Void)? = nil
    ) {
        self.configuration = configuration
        self.action = action
    }
}

#if DEBUG
#Preview {
    LargeThumbnailView(
        configuration: LargeThumbnailView.Configuration(
            title: "タイトル",
            imageURL: nil,
            createdAt: "2024/02/18 12:00"
        ),
        action: nil
    )
}
#endif

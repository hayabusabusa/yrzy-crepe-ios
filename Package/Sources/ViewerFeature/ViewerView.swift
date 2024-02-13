//
//  ViewerView.swift
//
//
//  Created by Shunya Yamada on 2024/02/10.
//

import NukeUI
import SwiftUI
import SwiftUIPager

// MARK: - View

public struct ViewerView: View {
    var configurations: [PageView.Configuration]
    /// 現在表示中のページの情報.
    ///
    /// [Usage - GitHub](https://github.com/fermoya/SwiftUIPager/blob/main/Documentation/Usage.md)
    @StateObject private var page = Page.first()

    public var body: some View {
        ZStack(alignment: .bottom) {
            Pager(
                page: page,
                data: configurations
            ) { configuration in
                PageView(configuration: configuration)
            }
            .horizontal(.endToStart)
            .itemAspectRatio(1)

            Slider(
                value: $page.index.converted(
                    forward: { Double($0) / Double(configurations.count - 1) },
                    backward: { Int($0) * (configurations.count - 1) }
                )
            )
            .padding()
        }
    }
}

extension ViewerView {
    struct PageView: View {
        var configuration: Configuration

        var body: some View {
            LazyImage(url: configuration.imageURL) { state in
                if let image = state.image {
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } else {
                    Color(.secondarySystemBackground)
                }
            }
        }
    }
}

extension ViewerView.PageView {
    struct Configuration: Identifiable, Hashable {
        let id: String
        let imageURL: URL
    }
}

private extension Binding {
    /// `Binding<T>` の型を別の型に変換する.
    ///
    /// - Seealso: [Zenn](https://zenn.dev/en3_hcl/articles/e65c1cde876456)
    /// - Parameters:
    ///   - forwardConverter: 変換処理
    ///   - backwardConverter: 変換後の値から元に戻す処理
    /// - Returns: 変換後の型を適応した `Binding`
    func converted<T>(
        forward forwardConverter: @escaping (Value) -> T,
        backward backwardConverter: @escaping (T) -> Value
    ) -> Binding<T> {
        .init(
            get: {
                return forwardConverter(self.wrappedValue)
            },
            set: {newValue in
                self.wrappedValue = backwardConverter(newValue)
            }
        )
    }
}

#if DEBUG
let urls = [
    URL(string: "https://avatars.githubusercontent.com/u/31949692?v=4")!,
    URL(string: "https://avatars.githubusercontent.com/u/31949692?v=3")!,
    URL(string: "https://avatars.githubusercontent.com/u/31949692?v=2")!
]

#Preview {
    ViewerView(
        configurations: urls.map {
            ViewerView.PageView.Configuration(
                id: $0.absoluteString,
                imageURL: $0
            )
        }
    )
}
#endif

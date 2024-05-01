//
//  SearchCancellableView.swift
//
//
//  Created by Shunya Yamada on 2024/04/29.
//

import SwiftUI

/// `.searchable` で表示した検索バーのキャンセルを検知するための `View`.
///
/// - note: `.searchable` を指定した `View` の子 `View` に指定して `.onChange(of:)` で値を監視して利用する.
/// - seealso: [stack overflow](https://stackoverflow.com/questions/69355159/swiftui-perform-action-when-cancel-is-clicked-searchable-function)
struct SearchCancellableView<Content: View>: View {
    @Environment(\.isSearching) var isSearching
    let content: (Bool) -> Content

    var body: some View {
        content(isSearching)
    }

    init(content: @escaping (Bool) -> Content) {
        self.content = content
    }
}

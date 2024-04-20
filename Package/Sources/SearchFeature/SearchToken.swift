//
//  SearchToken.swift
//
//
//  Created by Shunya Yamada on 2024/04/20.
//

import Foundation

public struct SearchToken: Identifiable, Hashable {
    /// トークンの ID.
    public var id: String
    /// トークンに表示するタイトル.
    public var title: String
    /// トークンの種別.
    public var type: TokenType

    public init(
        id: String = UUID().uuidString,
        title: String,
        type: TokenType
    ) {
        self.id = id
        self.title = title
        self.type = type
    }
}

public extension SearchToken {
    /// 検索トークンの種別.
    enum TokenType: CaseIterable, Hashable {
        /// 著者検索.
        case author
        /// 日付検索.
        case date
        /// タグ検索.
        case tags
    }
}

extension SearchToken {
    /// サジェストに表示する用のトークン一覧をセットで作成して返す.
    /// - Parameter text: テキストフィールドに入力された文字.
    /// - Returns: トークン一覧のセット.
    static func presets(with text: String) -> [SearchToken] {
        [
            SearchToken(
                title: text,
                type: .author
            ),
            SearchToken(
                title: text,
                type: .tags
            ),
            SearchToken(
                title: "日付",
                type: .date
            )
        ]
    }
}

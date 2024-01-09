//
//  Advertisement.swift
//
//
//  Created by Shunya Yamada on 2024/01/09.
//

import Foundation

/// Firestore の `/advertisements` 配下に格納される広告のデータ.
public struct Advertisement: Decodable, Equatable {
    /// タイトル.
    public let title: String
    /// サブタイトル.
    public let subTitle: String?
    /// ソースもしくは関連 URL.
    public let url: String
    /// 作成日時.
    public let createdAt: Date
    /// 画像 URL.
    public let imageURL: String?
    /// 値段.
    public let price: Int?
    /// タグ一覧.
    public let tags: [String]

    public init(title: String, 
                subTitle: String?,
                url: String,
                createdAt: Date,
                imageURL: String?,
                price: Int?,
                tags: [String]) {
        self.title = title
        self.subTitle = subTitle
        self.url = url
        self.createdAt = createdAt
        self.imageURL = imageURL
        self.price = price
        self.tags = tags
    }
}

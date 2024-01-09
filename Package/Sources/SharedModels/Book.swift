//
//  Book.swift
//
//
//  Created by Shunya Yamada on 2024/01/09.
//

import Foundation

/// Firestore の `/books` コレクション配下に格納されている作品のデータ.
public struct Book: Codable, Identifiable, Equatable {
    /// Firestore で Document に割り当てられている ID.
    public var id: String?
    /// 作品のタイトル
    public let title: String
    /// 作品の URL.
    public let url: String
    /// 作品が追加された日付.
    public let createdAt: Date
    /// 作品の画像一覧.
    public let imageURLs: [String]
    /// 作品のカテゴリー一覧.
    public let categories: [String]
    /// 作品の著者.
    public let author: String?
    /// 作品のサムネイル画像の URL.
    public let thumbnailURL: String?

    public init(id: String, 
                title: String,
                url: String,
                createdAt: Date,
                imageURLs: [String],
                categories: [String],
                author: String?,
                thumbnailURL: String?) {
        self.id = id
        self.title = title
        self.url = url
        self.createdAt = createdAt
        self.imageURLs = imageURLs
        self.categories = categories
        self.author = author
        self.thumbnailURL = thumbnailURL
    }
}

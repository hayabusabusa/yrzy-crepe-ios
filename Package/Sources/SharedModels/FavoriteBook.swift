//
//  FavoriteBook.swift
//
//
//  Created by Shunya Yamada on 2024/01/09.
//

import Foundation

/// Firestore の `/users/{UserID}/favorites` 配下に格納されるお気に入りの作品のデータ.
public struct FavoriteBook: Codable, Identifiable, Equatable {
    /// 作品の ID と同じ ID.
    public var id: String?
    /// 作品のタイトル.
    public let title: String
    /// お気に入りした日付.
    public let createdAt: Date
    /// お気に入りした作品が追加された日付.
    public let publishedAt: Date
    /// 作品のサムネイル画像の URL.
    public let thumbnailURL: String?

    public init(
        id: String,
        title: String,
        createdAt: Date,
        publishedAt: Date,
        thumbnailURL: String?
    ) {
        self.id = id
        self.title = title
        self.createdAt = createdAt
        self.publishedAt = publishedAt
        self.thumbnailURL = thumbnailURL
    }
}

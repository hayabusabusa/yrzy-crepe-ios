//
//  User.swift
//
//
//  Created by Shunya Yamada on 2024/01/09.
//

import Foundation

/// Firestore の `/user` 配下に格納される認証したユーザーのモデル.
public struct User: Codable, Identifiable, Equatable {
    /// Firestore で割り当てられているデータの ID.
    ///
    /// Firebase Auth でサインインしている UID と一致させる.
    public let id: String
    /// ユーザーが作成された日時.
    public let createdAt: Date

    public init(id: String, 
                createdAt: Date) {
        self.id = id
        self.createdAt = createdAt
    }
}

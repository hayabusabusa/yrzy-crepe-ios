//
//  Client.swift
//
//
//  Created by Shunya Yamada on 2024/01/09.
//

import Dependencies
import Foundation
import SharedModels

/// Firestore の操作を行うクライアント.
public struct FirestoreClient {
    /// Firestore の `/books/{id}` から任意のデータを取得する.
    public var fetchBook: @Sendable (String) async throws -> Book
    /// Firestore の `/books` から日付を降順に並べたデータ一覧を取得する.
    public var fetchLatestBooks: @Sendable (LatestBooksRequest) async throws -> [Book]
    /// Firestore の `/users/{userID}/favorites` から日付を降順に並べたデータ一覧を取得する.
    public var fetchLatestFavoriteBooks: @Sendable (LatestFavoriteBookRequest) async throws -> [FavoriteBook]
    /// Firestore の `/advertisements` からデータ一覧を取得する.
    public var fetchAdvertisements: @Sendable () async throws -> [Advertisement]

    public init(fetchBook: @Sendable @escaping (String) async throws -> Book,
                fetchLatestBooks: @Sendable @escaping (LatestBooksRequest) async throws -> [Book],
                fetchLatestFavoriteBooks: @Sendable @escaping (LatestFavoriteBookRequest) async throws -> [FavoriteBook],
                fetchAdvertisements: @Sendable @escaping () async throws -> [Advertisement]) {
        self.fetchBook = fetchBook
        self.fetchLatestBooks = fetchLatestBooks
        self.fetchLatestFavoriteBooks = fetchLatestFavoriteBooks
        self.fetchAdvertisements = fetchAdvertisements
    }
}

// MARK: - Requests

public extension FirestoreClient {
    /// 作品一覧を日付順に取得するためのリクエスト.
    struct LatestBooksRequest {
        /// ドキュメントを並び替える対象にするプロパティ名.
        public let orderBy: String
        /// 降順にするかどうか.
        public let isDescending: Bool
        /// ページネーションのために利用する日付.
        ///
        /// この日付以降のデータを取得する.
        public let afterDate: Date
        /// 一度に取得する件数.
        public let limit: Int

        public init(orderBy: String, 
                    isDescending: Bool,
                    afterDate: Date,
                    limit: Int) {
            self.orderBy = orderBy
            self.isDescending = isDescending
            self.afterDate = afterDate
            self.limit = limit
        }
    }
    
    /// お気に入りに登録した作品一覧を日付順に取得するためのリクエスト.
    struct LatestFavoriteBookRequest {
        /// ユーザー ID.
        public let userID: String
        /// ドキュメントを並び替える対象にするプロパティ名.
        public let orderBy: String
        /// 降順にするかどうか.
        public let isDescending: Bool
        /// ページネーションのために利用する日付.
        ///
        /// この日付以降のデータを取得する.
        public let afterDate: Date
        /// 一度に取得する件数.
        public let limit: Int

        public init(userID: String, 
                    orderBy: String,
                    isDescending: Bool,
                    afterDate: Date,
                    limit: Int) {
            self.userID = userID
            self.orderBy = orderBy
            self.isDescending = isDescending
            self.afterDate = afterDate
            self.limit = limit
        }
    }
}

// MARK: - Dependencies

extension FirestoreClient: TestDependencyKey {
    public static var previewValue: FirestoreClient {
        .init { _ in
            Book(id: "",
                 title: "",
                 url: "",
                 createdAt: Date(),
                 imageURLs: [],
                 categories: [],
                 author: nil,
                 thumbnailURL: nil)
        } fetchLatestBooks: { _ in
            []
        } fetchLatestFavoriteBooks: { _ in
            []
        } fetchAdvertisements: {
            []
        }
    }

    public static var testValue: FirestoreClient {
        .init { _ in
            unimplemented("\(Self.self)\(#function)")
        } fetchLatestBooks: { _ in
            unimplemented("\(Self.self)\(#function)")
        } fetchLatestFavoriteBooks: { _ in
            unimplemented("\(Self.self)\(#function)")
        } fetchAdvertisements: {
            unimplemented("\(Self.self)\(#function)")
        }
    }
}

extension DependencyValues {
    public var firestoreClient: FirestoreClient {
        get { self[FirestoreClient.self] }
        set { self[FirestoreClient.self] = newValue }
    }
}

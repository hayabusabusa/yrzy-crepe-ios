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
    /// Firestore の `/books` から任意の日付 1 日分のデータ一覧を取得する.
    public var fetchCertainDateBooks: @Sendable (CertainDateBooksRequest) async throws -> [Book]
    /// Firestore の `/books/{id}` にデータが存在するかどうかを返す.
    public var bookExists: @Sendable (String) async throws -> Bool
    /// Firestore の `/users/{userID}/favorites` から日付を降順に並べたデータ一覧を取得する.
    public var fetchLatestFavoriteBooks: @Sendable (LatestFavoriteBookRequest) async throws -> [FavoriteBook]
    /// Firestore の `/advertisements` からデータ一覧を取得する.
    public var fetchAdvertisements: @Sendable () async throws -> [Advertisement]
    /// Firestore の `/users/{userID}` にデータを追加する.
    public var addUser: @Sendable (User) async throws -> Void
    /// Firestore の `/users/{userID}/favorites/{documentID}` からデータを削除する.
    public var removeFavoriteBook: @Sendable (RemoveFavoriteBookRequest) async throws -> Void

    public init(fetchBook: @Sendable @escaping (String) async throws -> Book,
                fetchLatestBooks: @Sendable @escaping (LatestBooksRequest) async throws -> [Book],
                fetchCertainDateBooks: @Sendable @escaping (CertainDateBooksRequest) async throws -> [Book],
                bookExists: @Sendable @escaping (String) async throws -> Bool,
                fetchLatestFavoriteBooks: @Sendable @escaping (LatestFavoriteBookRequest) async throws -> [FavoriteBook],
                fetchAdvertisements: @Sendable @escaping () async throws -> [Advertisement],
                addUser: @Sendable @escaping (User) async throws -> Void,
                removeFavoriteBook: @Sendable @escaping (RemoveFavoriteBookRequest) async throws -> Void) {
        self.fetchBook = fetchBook
        self.fetchLatestBooks = fetchLatestBooks
        self.fetchCertainDateBooks = fetchCertainDateBooks
        self.bookExists = bookExists
        self.fetchLatestFavoriteBooks = fetchLatestFavoriteBooks
        self.fetchAdvertisements = fetchAdvertisements
        self.addUser = addUser
        self.removeFavoriteBook = removeFavoriteBook
    }
}

// MARK: - Requests

public extension FirestoreClient {
    /// 作品一覧を日付順に取得するためのリクエスト.
    struct LatestBooksRequest {
        /// ページネーションのために利用する日付.
        ///
        /// この日付以降のデータを取得する.
        public let afterDate: Date
        /// 一度に取得する件数.
        public let limit: Int

        public init(afterDate: Date,
                    limit: Int) {
            self.afterDate = afterDate
            self.limit = limit
        }
    }
    
    /// 任意の日付 1 日文のデータを日付順に取得するためのリクエスト.
    struct CertainDateBooksRequest {
        /// 取得する日付.
        public let date: Date
        /// 降順にするかどうか.
        public let isDescending: Bool
        /// 一度に取得する件数.
        public let limit: Int

        public init(
            date: Date,
            isDescending: Bool,
            limit: Int
        ) {
            self.date = date
            self.isDescending = isDescending
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

    /// お気に入りに登録した作品を削除するためのリクエスト.
    struct RemoveFavoriteBookRequest {
        /// ユーザー ID.
        public let userID: String
        /// `/users/{userID}/favorites` に格納したドキュメントの ID.
        public let documentID: String

        public init(userID: String, 
                    documentID: String) {
            self.userID = userID
            self.documentID = documentID
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
        } fetchCertainDateBooks: { _ in
            []
        } bookExists: { _ in
            false
        } fetchLatestFavoriteBooks: { _ in
            []
        } fetchAdvertisements: {
            []
        } addUser: { _ in

        } removeFavoriteBook: { _ in }
    }

    public static var testValue: FirestoreClient {
        .init { _ in
            unimplemented("\(Self.self)\(#function)")
        } fetchLatestBooks: { _ in
            unimplemented("\(Self.self)\(#function)")
        } fetchCertainDateBooks: { _ in
            unimplemented("\(Self.self)\(#function)")
        } bookExists: { _ in
            unimplemented("\(Self.self)\(#function)")
        } fetchLatestFavoriteBooks: { _ in
            unimplemented("\(Self.self)\(#function)")
        } fetchAdvertisements: {
            unimplemented("\(Self.self)\(#function)")
        } addUser: { _ in
            unimplemented("\(Self.self)\(#function)")
        } removeFavoriteBook: { _ in
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

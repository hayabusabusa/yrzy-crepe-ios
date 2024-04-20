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
    /// Firestore の `/books` から条件に一致するデータを検索して取得する.
    public var searchBooks: @Sendable (SearchBooksRequest) async throws -> [Book]
    /// Firestore の `/books/{id}` にデータが存在するかどうかを返す.
    public var bookExists: @Sendable (String) async throws -> Bool
    /// Firestore の `/users/{userID}/favorites` にデータを追加する.
    public var addFavoriteBook: @Sendable (AddFavoriteBookRequest) async throws -> Void
    /// Firestore の `/users/{userID}/favorites` から日付を降順に並べたデータ一覧を取得する.
    public var fetchLatestFavoriteBooks: @Sendable (LatestFavoriteBookRequest) async throws -> [FavoriteBook]
    /// Firestore の `/users/{userID}/favorites` にデータが存在するかどうか返す.
    public var favoriteBookExists: @Sendable (FavoriteBookExistsRequest) async throws -> Bool
    /// Firestore の `/advertisements` からデータ一覧を取得する.
    public var fetchAdvertisements: @Sendable () async throws -> [Advertisement]
    /// Firestore の `/users/{userID}` にデータを追加する.
    public var addUser: @Sendable (User) async throws -> Void
    /// Firestore の `/users/{userID}/favorites/{documentID}` からデータを削除する.
    public var removeFavoriteBook: @Sendable (RemoveFavoriteBookRequest) async throws -> Void

    public init(
        fetchBook: @Sendable @escaping (String) async throws -> Book,
        fetchLatestBooks: @Sendable @escaping (LatestBooksRequest) async throws -> [Book],
        fetchCertainDateBooks: @Sendable @escaping (CertainDateBooksRequest) async throws -> [Book],
        searchBooks: @Sendable @escaping (SearchBooksRequest) async throws -> [Book],
        bookExists: @Sendable @escaping (String) async throws -> Bool,
        addFavoriteBook: @Sendable @escaping (AddFavoriteBookRequest) async throws -> Void,
        fetchLatestFavoriteBooks: @Sendable @escaping (LatestFavoriteBookRequest) async throws -> [FavoriteBook],
        favoriteBookExists: @Sendable @escaping (FavoriteBookExistsRequest) async throws -> Bool,
        fetchAdvertisements: @Sendable @escaping () async throws -> [Advertisement],
        addUser: @Sendable @escaping (User) async throws -> Void,
        removeFavoriteBook: @Sendable @escaping (RemoveFavoriteBookRequest) async throws -> Void
    ) {
        self.fetchBook = fetchBook
        self.fetchLatestBooks = fetchLatestBooks
        self.fetchCertainDateBooks = fetchCertainDateBooks
        self.searchBooks = searchBooks
        self.bookExists = bookExists
        self.addFavoriteBook = addFavoriteBook
        self.fetchLatestFavoriteBooks = fetchLatestFavoriteBooks
        self.favoriteBookExists = favoriteBookExists
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

        public init(
            afterDate: Date,
            limit: Int
        ) {
            self.afterDate = afterDate
            self.limit = limit
        }
    }
    
    /// 任意の日付 1 日分のデータを日付順に取得するためのリクエスト.
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

    /// 作品を検索するためのリクエスト.
    struct SearchBooksRequest {
        /// 日付( 必須 ).
        public let date: Date
        /// 検索する作品のタイトル.
        public let title: String?
        /// 検索する作品の著者名.
        public let author: String?

        public init(
            date: Date,
            title: String?,
            author: String?
        ) {
            self.date = date
            self.title = title
            self.author = author
        }
    }

    /// 新しく作品をお気に入りに登録するためのリクエスト.
    struct AddFavoriteBookRequest {
        /// お気に入りしたユーザーの ID.
        public let userID: String
        /// お気に入り作品のデータ.
        public let favoriteBook: FavoriteBook

        public init(
            userID: String,
            favoriteBook: FavoriteBook
        ) {
            self.userID = userID
            self.favoriteBook = favoriteBook
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

        public init(
            userID: String,
            orderBy: String,
            isDescending: Bool,
            afterDate: Date,
            limit: Int
        ) {
            self.userID = userID
            self.orderBy = orderBy
            self.isDescending = isDescending
            self.afterDate = afterDate
            self.limit = limit
        }
    }
    
    /// 作品がお気に入りに登録されているかどうか取得するためのリクエスト.
    struct FavoriteBookExistsRequest {
        /// ユーザーの ID.
        public let userID: String
        /// 作品の ID.
        public let bookID: String?

        public init(
            userID: String,
            bookID: String?
        ) {
            self.userID = userID
            self.bookID = bookID
        }
    }

    /// お気に入りに登録した作品を削除するためのリクエスト.
    struct RemoveFavoriteBookRequest {
        /// ユーザー ID.
        public let userID: String
        /// 作品の ID.
        ///
        /// `/users/{userID}/favorites` に格納したドキュメントの ID.
        public let bookID: String?

        public init(
            userID: String,
            bookID: String?
        ) {
            self.userID = userID
            self.bookID = bookID
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
        } searchBooks: { _ in
            []
        } bookExists: { _ in
            false
        } addFavoriteBook: { _ in

        } fetchLatestFavoriteBooks: { _ in
            []
        } favoriteBookExists: { _ in
            false
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
        } searchBooks: { _ in
            unimplemented("\(Self.self)\(#function)")
        } bookExists: { _ in
            unimplemented("\(Self.self)\(#function)")
        } addFavoriteBook: { _ in
            unimplemented("\(Self.self)\(#function)")
        } fetchLatestFavoriteBooks: { _ in
            unimplemented("\(Self.self)\(#function)")
        } favoriteBookExists: { _ in
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

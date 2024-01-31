//
//  Live.swift
//
//
//  Created by Shunya Yamada on 2024/01/09.
//

@_exported import FirestoreClient
import FirebaseFirestore
import FirebaseFirestoreSwift
import Foundation
import Dependencies
import SharedModels

extension FirestoreClient: DependencyKey {
    public static var liveValue: FirestoreClient {
        Self.live()
    }

    private static func live() -> Self {
        let db = Firestore.firestore()
        let encoder = Firestore.Encoder()
        let decoder = Firestore.Decoder()

        return .init { documentID in
            let collectionPath = Path.books.collection
            let snapshot = try await db.collection(collectionPath)
                .document(documentID)
                .getDocument()
            var decoded = try decoder.decode(Book.self, from: snapshot.data() ?? [:])
            decoded.id = snapshot.documentID

            return decoded
        } fetchLatestBooks: { request in
            let collectionPath = Path.books.collection
            let snapshot = try await db.collection(collectionPath)
                .order(by: request.orderBy, descending: request.isDescending)
                .start(after: [request.afterDate])
                .limit(to: request.limit)
                .getDocuments()

            return try snapshot.documents
                .map { document in
                    var decoded = try decoder.decode(Book.self, from: document.data())
                    decoded.id = document.documentID
                    return decoded
                }
        } fetchCertainDateBooks: { request in
            let collectionPath = Path.books.collection
            let date = request.date.startAndEnd
            let snapshot = try await db.collection(collectionPath)
                .order(by: "createdAt", descending: request.isDescending)
                .start(at: [date.start])
                .end(at: [date.end])
                .limit(to: request.limit)
                .getDocuments()

            return try snapshot.documents
                .map { document in
                    var decoded = try decoder.decode(Book.self, from: document.data())
                    decoded.id = document.documentID
                    return decoded
                }
        } bookExists: { documentID in
            let collectionPath = Path.books.collection
            let snapshot = try await db.collection(collectionPath)
                .document(documentID)
                .getDocument()

            return snapshot.exists
        } fetchLatestFavoriteBooks: { request in
            let collectionPath = Path.favorites(for: request.userID).collection
            let snapshot = try await db.collection(collectionPath)
                .order(by: request.orderBy, descending: request.isDescending)
                .start(after: [request.afterDate])
                .limit(to: request.limit)
                .getDocuments()

            return try snapshot.documents
                .map { document in
                    var decoded = try decoder.decode(FavoriteBook.self, from: document.data())
                    decoded.id = document.documentID
                    return decoded
                }
        } fetchAdvertisements: {
            let collectionPath = Path.advertisements.collection
            let snapshot = try await db.collection(collectionPath)
                .order(by: "createdAt", descending: true)
                .getDocuments()

            return try snapshot.documents
                .map { try decoder.decode(Advertisement.self, from: $0.data()) }
        } addUser: { user in
            let collectionPath = Path.users.collection
            let encoded = try encoder.encode(user)

            try await db.collection(collectionPath)
                .addDocument(data: encoded)
        } removeFavoriteBook: { request in
            let collectionPath = Path.favorites(for: request.userID).collection
            try await db.collection(collectionPath)
                .document(request.documentID)
                .delete()
        }
    }
}

private struct Path {
    let collection: String

    static let books = Self.init(collection: "public/v1/books")
    static let users = Self.init(collection: "public/v1/users")
    static let advertisements = Self.init(collection: "public/v1/advertisements")

    static func favorites(for userID: String) -> Self {
        .init(collection: "public/v1/users/\(userID)/favorites")
    }
}

private extension Date {
    /// その日の始まり( 0 時 0 分 )と終わり( 23 時 59 分 )を返す.
    var startAndEnd: (start: Date, end: Date) {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: self)
        let end = calendar.date(byAdding: DateComponents(day: 1, second: -1), to: self) ?? self
        return (start: start, end: end)
    }
}

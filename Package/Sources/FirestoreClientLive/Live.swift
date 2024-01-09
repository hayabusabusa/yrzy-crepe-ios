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
        let decoder = Firestore.Decoder()

        return .init { documentID in
            let snapshot = try await db.collection(Path.books.collection)
                .document(documentID)
                .getDocument()
            var decoded = try decoder.decode(Book.self, from: snapshot.data() ?? [:])
            decoded.id = snapshot.documentID
            return decoded
        } fetchLatestBooks: { request in
            let snapshot = try await db.collection(Path.books.collection)
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
        } fetchLatestFavoriteBooks: { request in
            let snapshot = try await db.collection(Path.favorites(for: request.userID).collection)
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
            let snapshot = try await db.collection(Path.advertisements.collection)
                .order(by: "createdAt", descending: true)
                .getDocuments()
            return try snapshot.documents
                .map { try decoder.decode(Advertisement.self, from: $0.data()) }
        }
    }
}

private struct Path {
    let collection: String
    var document: String?

    static let books = Self.init(collection: "public/v1/books")
    static let advertisements = Self.init(collection: "public/v1/advertisements")

    static func favorites(for userID: String) -> Self {
        .init(collection: "public/v1/users/\(userID)/favorites")
    }
}

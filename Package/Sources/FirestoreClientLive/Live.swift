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

        return .init { request in
            let snapshot = try await db.collection(Path.books.collection)
                .order(by: request.orderBy, descending: request.isDescending)
                .start(after: [request.afterDate])
                .limit(to: request.limit).getDocuments()
            return try snapshot.documents
                .map { document in
                    var decoded = try decoder.decode(Book.self, from: document.data())
                    decoded.id = document.documentID
                    return decoded
                }
        }
    }
}

private struct Path {
    let collection: String
    var document: String?

    static let books = Self.init(collection: "public/v1/books")
}

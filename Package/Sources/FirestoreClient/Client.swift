//
//  Client.swift
//
//
//  Created by Shunya Yamada on 2024/01/09.
//

import Dependencies
import Foundation

/// Firestore の操作を行うクライアント.
public struct FirestoreClient {
    public init() {}
}

extension FirestoreClient: TestDependencyKey {
    public static var previewValue: FirestoreClient {
        .init()
    }

    public static var testValue: FirestoreClient {
        .init()
    }
}

extension DependencyValues {
    public var firestoreClient: FirestoreClient {
        get { self[FirestoreClient.self] }
        set { self[FirestoreClient.self] = newValue }
    }
}

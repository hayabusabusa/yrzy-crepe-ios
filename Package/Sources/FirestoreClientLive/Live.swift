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

extension FirestoreClient: DependencyKey {
    public static var liveValue: FirestoreClient {
        .init()
    }
}

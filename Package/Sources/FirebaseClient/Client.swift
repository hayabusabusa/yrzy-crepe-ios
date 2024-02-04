//
//  Client.swift
//
//
//  Created by Shunya Yamada on 2024/02/04.
//

import Dependencies
import Foundation

/// `Firebase` のセットアップ処理を行うクライアント.
public struct FirebaseClient {
    /// `Firebase` の必須セットアップ処理を行う.
    ///
    /// セットアップについては [公式ドキュメント](https://firebase.google.com/docs/ios/setup?hl=ja) を参照.
    public var configure: @Sendable () -> Void

    public init(configure: @Sendable @escaping () -> Void) {
        self.configure = configure
    }
}

// MARK: - Dependencies

extension FirebaseClient: TestDependencyKey {
    public static var previewValue: FirebaseClient {
        .init {}
    }

    public static var testValue: FirebaseClient {
        .init {
            unimplemented("\(Self.self)\(#function)")
        }
    }
}

extension DependencyValues {
    public var firebaseClient: FirebaseClient {
        get { self[FirebaseClient.self] }
        set { self[FirebaseClient.self] = newValue }
    }
}

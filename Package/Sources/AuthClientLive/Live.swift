//
//  Live.swift
//
//
//  Created by Shunya Yamada on 2024/01/09.
//

@_exported import AuthClient
import Dependencies
import FirebaseAuth
import Foundation
import SharedModels

extension AuthClient: DependencyKey {
    public static var liveValue: AuthClient {
        Self.live()
    }

    private static func live() -> Self {
        let auth = Auth.auth()

        return Self.init {
            auth.currentUser != nil
        } uid: {
            auth.currentUser?.uid
        } signInAsAnonymousUser: {
            let result = try await auth.signInAnonymously()
            let user = SharedModels.User(id: result.user.uid,
                                         createdAt: Date())
            return user
        }
    }
}

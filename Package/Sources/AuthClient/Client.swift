//
//  Client.swift
//
//
//  Created by Shunya Yamada on 2024/01/09.
//

import Dependencies
import Foundation
import SharedModels

/// Firebase Auth の操作を行うクライアント.
public struct AuthClient {
    /// サインイン済みのユーザーかどうかを返す.
    public var isSignIn: @Sendable () -> Bool
    /// ユーザー ID を返す.
    public var uid: @Sendable () -> String?
    /// 匿名認証でサインインする.
    public var signInAsAnonymousUser: @Sendable () async throws -> SharedModels.User

    public init(isSignIn: @Sendable @escaping () -> Bool,
                uid: @Sendable @escaping () -> String?,
                signInAsAnonymousUser: @Sendable @escaping () async throws -> SharedModels.User) {
        self.isSignIn = isSignIn
        self.uid = uid
        self.signInAsAnonymousUser = signInAsAnonymousUser
    }
}

// MARK: - Dependencies

extension AuthClient: TestDependencyKey {
    public static var previewValue: AuthClient {
        .init {
            false
        } uid: {
            nil
        } signInAsAnonymousUser: {
            User(id: "",
                 createdAt: Date())
        }
    }

    public static var testValue: AuthClient {
        .init {
            unimplemented("\(Self.self)\(#function)")
        } uid: {
            unimplemented("\(Self.self)\(#function)")
        } signInAsAnonymousUser: {
            unimplemented("\(Self.self)\(#function)")
        }
    }
}

extension DependencyValues {
    public var authClient: AuthClient {
        get { self[AuthClient.self] }
        set { self[AuthClient.self] = newValue }
    }
}

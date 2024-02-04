//
//  AppDelegateFeature.swift
//
//
//  Created by Shunya Yamada on 2024/02/04.
//

import ComposableArchitecture
import Dependencies
import FirebaseClient
import Foundation

@Reducer
public struct AppDelegateFeature {
    public struct State: Equatable {
        public init() {}
    }

    public enum Action {
        /// `AppDelegate` の `application(_:didFinishLaunchingWithOptions:)` 完了時に実行されるアクション.
        case didFinishLaunching
    }

    @Dependency(\.firebaseClient) var firebaseClient

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .didFinishLaunching:
                self.firebaseClient.configure()
                return .none
            }
        }
    }

    public init() {}
}

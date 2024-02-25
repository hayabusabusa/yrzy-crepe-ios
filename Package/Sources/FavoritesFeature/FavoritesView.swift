//
//  FavoritesView.swift
//
//
//  Created by Shunya Yamada on 2024/02/25.
//

import ComposableArchitecture
import SwiftUI

// MARK: - Reducer

@Reducer
public struct FavoritesFeature {
    public struct State: Equatable {

    }

    public enum Action {
        case task
    }

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .task:

                return .none
            }
        }
    }

    public init() {}
}

// MARK: - View

public struct FavoritesView: View {
    let store: StoreOf<FavoritesFeature>

    public var body: some View {
        Text("")
    }

    public init(store: StoreOf<FavoritesFeature>) {
        self.store = store
    }
}

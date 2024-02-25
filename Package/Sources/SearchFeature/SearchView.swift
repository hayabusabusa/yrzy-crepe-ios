//
//  SearchView.swift
//
//
//  Created by Shunya Yamada on 2024/02/24.
//

import ComposableArchitecture
import SwiftUI

// MARK: - Reducer

@Reducer
public struct SearchFeature {
    public struct State: Equatable {}

    public enum Action {
        case searchCancelTapped
    }

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .searchCancelTapped:

                return .none
            }
        }
    }

    public init() {}
}

// MARK: - View

public struct SearchView: View {
    let store: StoreOf<SearchFeature>

    public var body: some View {
        WithViewStore(store, observe: { $0 }) { viewStore in
            Text("")
        }
    }

    public init(store: StoreOf<SearchFeature>) {
        self.store = store
    }
}

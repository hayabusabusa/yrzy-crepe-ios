//
//  AppView.swift
//
//
//  Created by Shunya Yamada on 2024/01/09.
//

import ComposableArchitecture
import GalleryFeature
import SwiftUI

// MARK: - Reducer

@Reducer
public struct AppFeature {
    public struct State {
        public var appDelegate = AppDelegateFeature.State()

        public init(appDelegate: AppDelegateFeature.State = AppDelegateFeature.State()) {
            self.appDelegate = appDelegate
        }
    }

    public enum Action {
        /// `AppDelegate` の各種デリゲートを受け取るアクション.
        case appDelegate(AppDelegateFeature.Action)
    }

    public var body: some ReducerOf<Self> {
        Scope(state: \.appDelegate, action: \.appDelegate) {
            AppDelegateFeature()
        }

        Reduce { state, action in
            switch action {
            case .appDelegate(.didFinishLaunching):
                return .none
            }
        }
    }

    public init() {}
}

// MARK: - View

public struct AppView: View {
    let store: StoreOf<AppFeature>

    public var body: some View {
        GalleryView(store: Store(initialState: GalleryFeature.State()) {
            GalleryFeature()
        })
    }

    public init(store: StoreOf<AppFeature>) {
        self.store = store
    }
}

#if DEBUG
#Preview {
    AppView(
        store: Store(initialState: AppFeature.State()) {
            AppFeature()
        }
    )
}
#endif

//
//  GalleryView.swift
//
//
//  Created by Shunya Yamada on 2024/01/09.
//

import AuthClient
import ComposableArchitecture
import FirestoreClient
import NukeUI
import SharedModels
import SwiftUI

// MARK: - Reducer

@Reducer
public struct GalleryFeature {
    public struct State: Equatable {
        public var books = IdentifiedArrayOf<Book>()
        public var isLoading = false

        public init(
            books: IdentifiedArrayOf<Book> = IdentifiedArrayOf<Book>(),
            isLoading: Bool = false
        ) {
            self.books = books
            self.isLoading = isLoading
        }
    }

    public enum Action {
        /// 画面に必要な情報が全て返ってきた時の `Action`.
        case response(Result<[Book], Error>)
        /// 非同期処理を実行するための `Action`.
        case task
    }

    @Dependency(\.authClient) var authClient
    @Dependency(\.date) var dateGenerator
    @Dependency(\.firestoreClient) var firestoreClient

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case let .response(.success(books)):
                state.books = IdentifiedArray(uniqueElements: books)
                state.isLoading = false

                return .none
            case .response(.failure):
                state.isLoading = false

                return .none
            case .task:
                state.isLoading = true

                return .run { send in
                    // サインインしていない場合は匿名認証して新しくユーザーのデータを保存する
                    let isSignIn = self.authClient.isSignIn()
                    if !isSignIn {
                        let user = try await self.authClient.signInAsAnonymousUser()
                        try await self.firestoreClient.addUser(user)
                    }

                    await send(
                        .response(
                            Result {
                                try await self.firestoreClient.fetchLatestBooks(
                                    FirestoreClient.LatestBooksRequest(
                                        orderBy: "createdAt",
                                        isDescending: true,
                                        afterDate: dateGenerator.now,
                                        limit: 10
                                    )
                                )
                            }
                        )
                    )
                }
            }
        }
    }

    public init() {}
}

// MARK: - View

public struct GalleryView: View {
    let store: StoreOf<GalleryFeature>

    public var body: some View {
        WithViewStore(store, observe: { $0 }) { viewStore in
            NavigationStack {
                if viewStore.isLoading {
                    ProgressView()
                } else {
                    ScrollView {
                        LazyVStack {
                            GalleryHeaderView(
                                pageViewConfigurations: viewStore.books.prefix(3).map {
                                    .init(
                                        id: $0.id, 
                                        title: $0.title,
                                        imageURL: $0.thumbnailURL
                                    )
                                }
                            )

                            GallerySectionTitleView(
                                title: "最近追加された作品",
                                buttonTitle: "もっとみる",
                                action: {}
                            )

                            GallerySectionView(
                                configurations: viewStore.books.map {
                                    .init(
                                        id: $0.id,
                                        title: $0.title,
                                        imageURL: $0.thumbnailURL
                                    )
                                },
                                action: { index in
                                    print(index)
                                }
                            )
                        }
                    }
                    .padding(.top)
                }
            }
            .task {
                store.send(.task)
            }
        }
    }

    public init(store: StoreOf<GalleryFeature>) {
        self.store = store
    }
}

#if DEBUG
#Preview {
    GalleryView(
        store: Store(initialState: GalleryFeature.State()) {
            GalleryFeature()
        } withDependencies: {
            $0.authClient.isSignIn = { true }
            $0.firestoreClient.fetchLatestBooks = { _ in
                [
                    .init(
                        id: UUID().uuidString,
                        title: "TEST",
                        url: "",
                        createdAt: Date(),
                        imageURLs: [],
                        categories: [],
                        author: nil,
                        thumbnailURL: "https://avatars.githubusercontent.com/u/31949692?v=4"
                    )
                ]
            }
        }
    )
}
#endif

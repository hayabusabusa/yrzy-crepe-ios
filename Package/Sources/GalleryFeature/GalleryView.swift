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
        public var latestBooks = IdentifiedArrayOf<Book>()
        public var lastYearBooks = IdentifiedArrayOf<Book>()
        public var isLoading = false

        public init(
            latestBooks: IdentifiedArrayOf<Book> = IdentifiedArrayOf<Book>(),
            lastYearBooks: IdentifiedArrayOf<Book> = IdentifiedArrayOf<Book>(),
            isLoading: Bool = false
        ) {
            self.latestBooks = latestBooks
            self.lastYearBooks = lastYearBooks
            self.isLoading = isLoading
        }
    }

    public enum Action {
        /// 画面に必要な情報が全て返ってきた時の `Action`.
        case response(Result<Response, Error>)
        /// 非同期処理を実行するための `Action`.
        case task
    }

    public struct Response {
        let latestBooks: [Book]
        let lastYearBooks: [Book]

        public init(
            latestBooks: [Book],
            lastYearBooks: [Book]
        ) {
            self.latestBooks = latestBooks
            self.lastYearBooks = lastYearBooks
        }
    }

    @Dependency(\.authClient) var authClient
    @Dependency(\.date) var dateGenerator
    @Dependency(\.firestoreClient) var firestoreClient

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case let .response(.success(response)):
                state.latestBooks = IdentifiedArray(uniqueElements: response.latestBooks)
                state.lastYearBooks = IdentifiedArray(uniqueElements: response.lastYearBooks)
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
                                try await self.fetchGalleryBooks()
                            }
                        )
                    )
                }
            }
        }
    }

    public init() {}
}

// MARK: Reducer Private

private extension GalleryFeature {
    /// ギャラリー画面の表示に必要なデータをすべて取得する.
    func fetchGalleryBooks() async throws -> Response {
        let now = dateGenerator.now
        async let fetchLatestBooksTask = firestoreClient.fetchLatestBooks(
            FirestoreClient.LatestBooksRequest(
                orderBy: "createdAt",
                isDescending: true,
                afterDate: now,
                limit: 6
            )
        )
        let lastYear = now.addingTimeInterval(-(365 * 24 * 60 * 60))
        async let fetchLastYearBooksTask = firestoreClient.fetchCertainDateBooks(
            FirestoreClient.CertainDateBooksRequest(
                date: lastYear,
                isDescending: true,
                limit: 6
            )
        )

        let results = try await (fetchLatestBooksTask, fetchLastYearBooksTask)
        return Response(
            latestBooks: results.0,
            lastYearBooks: results.1
        )
    }
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
                                pageViewConfigurations: viewStore.latestBooks.prefix(3).map {
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
                                configurations: viewStore.latestBooks.map {
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

                            let lastYearBooks = viewStore.lastYearBooks
                            if !lastYearBooks.isEmpty {
                                GallerySectionTitleView(
                                    title: "あの日追加された作品",
                                    buttonTitle: "もっとみる",
                                    action: {}
                                )

                                GallerySectionView(
                                    configurations: lastYearBooks.map {
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
let booksStub = Array(repeating: 0, count: 6)
    .map { _ in
        Book(
            id: UUID().uuidString,
            title: "TEST",
            url: "",
            createdAt: Date(),
            imageURLs: [],
            categories: [],
            author: nil,
            thumbnailURL: "https://avatars.githubusercontent.com/u/31949692?v=4"
        )
    }

#Preview {
    GalleryView(
        store: Store(initialState: GalleryFeature.State()) {
            GalleryFeature()
        } withDependencies: {
            $0.authClient.isSignIn = { true }
            $0.firestoreClient.fetchLatestBooks = { _ in booksStub }
            $0.firestoreClient.fetchCertainDateBooks = { _ in booksStub }
        }
    )
}
#endif

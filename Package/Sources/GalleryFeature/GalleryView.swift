//
//  GalleryView.swift
//
//
//  Created by Shunya Yamada on 2024/01/09.
//

import AuthClient
import BookshelfFeature
import ComposableArchitecture
import FirestoreClient
import NukeUI
import SharedExtensions
import SharedModels
import SwiftUI
import ViewerFeature

// MARK: - Reducer

@Reducer
public struct GalleryFeature {
    public struct State: Equatable {
        public var latestBooks = IdentifiedArrayOf<Book>()
        public var lastYearBooks = IdentifiedArrayOf<Book>()
        public var isLoading = false
        @PresentationState public var bookshelf: BookshelfFeature.State?
        @PresentationState public var viewer: ViewerFeature.State?

        public init(
            latestBooks: IdentifiedArrayOf<Book> = IdentifiedArrayOf<Book>(),
            lastYearBooks: IdentifiedArrayOf<Book> = IdentifiedArrayOf<Book>(),
            isLoading: Bool = false,
            bookshelf: BookshelfFeature.State? = nil,
            viewer: ViewerFeature.State? = nil
        ) {
            self.latestBooks = latestBooks
            self.lastYearBooks = lastYearBooks
            self.isLoading = isLoading
            self.bookshelf = bookshelf
            self.viewer = viewer
        }
    }

    public enum Action {
        /// 本棚画面い遷移する `Action`.
        case bookshelf(PresentationAction<BookshelfFeature.Action>)
        /// 最近追加された作品一覧のアイテムがタップされた時の `Action`.
        case latestBookTapped(Int)
        /// 最近追加された作品一覧のもっとみるボタンがタップされた時の `Action`.
        case latestBookMoreTapped
        /// 1年前に追加された作品一覧のアイテムがタップされた時の `Action`.
        case lastYearBookTapped(Int)
        /// 1年前に追加された作品一覧のもっとみるボタンがタップされた時の `Action`.
        case lastYearBookMoreTapped
        /// 引っ張って更新の `Action`.
        case pullToRefresh
        /// ビューワー画面に遷移する `Aciton`.
        case viewer(PresentationAction<ViewerFeature.Action>)
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
            case .bookshelf:

                return .none
            case let .latestBookTapped(index):
                state.viewer = ViewerFeature.State(
                    book: state.latestBooks[index]
                )

                return .none
            case .latestBookMoreTapped:
                state.bookshelf = BookshelfFeature.State(
                    collection: .latest
                )

                return .none
            case let .lastYearBookTapped(index):
                state.viewer = ViewerFeature.State(
                    book: state.lastYearBooks[index]
                )

                return .none
            case .lastYearBookMoreTapped:
                state.bookshelf = BookshelfFeature.State(
                    collection: .lastYear
                )

                return .none
            case .pullToRefresh:
                state.isLoading = true

                return .run { send in
                    await send(
                        .response(
                            Result {
                                try await self.fetchGalleryBooks()
                            }
                        )
                    )
                }
            case .viewer:

                return .none
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
        .ifLet(\.$bookshelf, action: \.bookshelf) {
            BookshelfFeature()
        }
        .ifLet(\.$viewer, action: \.viewer) {
            ViewerFeature()
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
        async let fetchLastYearBooksTask = firestoreClient.fetchCertainDateBooks(
            FirestoreClient.CertainDateBooksRequest(
                date: now.lastYear,
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

                            GalleryMenuView()
                                .padding(.top, 8)

                            GallerySectionTitleView(
                                title: "最近追加された作品",
                                buttonTitle: "もっとみる",
                                action: {
                                    viewStore.send(.latestBookMoreTapped)
                                }
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
                                    viewStore.send(.latestBookTapped(index))
                                }
                            )

                            let lastYearBooks = viewStore.lastYearBooks
                            if !lastYearBooks.isEmpty {
                                GallerySectionTitleView(
                                    title: "1年前に追加された作品",
                                    buttonTitle: "もっとみる",
                                    action: {
                                        viewStore.send(.lastYearBookMoreTapped)
                                    }
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
                                        viewStore.send(.lastYearBookTapped(index))
                                    }
                                )
                            }
                        }
                    }
                    .padding(.top)
                    .refreshable {
                        viewStore.send(.pullToRefresh)
                    }
                }
            }
            .task {
                store.send(.task)
            }
            .fullScreenCover(
                store: store.scope(
                    state: \.$viewer,
                    action: { .viewer($0) }
                )
            ) { store in
                NavigationStack {
                    ViewerView(store: store)
                }
            }
            .fullScreenCover(
                store: store.scope(
                    state: \.$bookshelf,
                    action: { .bookshelf($0) }
                )
            ) { store in
                NavigationStack {
                    BookshelfView(store: store)
                }
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

//
//  GalleryView.swift
//
//
//  Created by Shunya Yamada on 2024/01/09.
//

import AuthClient
import BookshelfFeature
import ComposableArchitecture
import FavoritesFeature
import FirestoreClient
import NukeUI
import RandomDateGenerator
import SearchFeature
import SharedExtensions
import SharedModels
import SwiftUI
import ViewerFeature

// MARK: - Reducer

@Reducer
public struct GalleryFeature {
    /// 画面遷移をまとめた子 `Reducer`.
    @Reducer
    public struct Destination {
        public enum State: Equatable {
            case bookshelf(BookshelfFeature.State)
            case favorites(FavoritesFeature.State)
            case search(SearchFeature.State)
            case viewer(ViewerFeature.State)
        }

        public enum Action {
            case bookshelf(BookshelfFeature.Action)
            case favorites(FavoritesFeature.Action)
            case search(SearchFeature.Action)
            case viewer(ViewerFeature.Action)
        }

        public var body: some ReducerOf<Self> {
            Scope(state: \.bookshelf, action: \.bookshelf) {
                BookshelfFeature()
            }
            Scope(state: \.favorites, action: \.favorites) {
                FavoritesFeature()
            }
            Scope(state: \.search, action: \.search) {
                SearchFeature()
            }
            Scope(state: \.viewer, action: \.viewer) {
                ViewerFeature()
            }
        }
    }

    public struct State: Equatable {
        public var latestBooks = IdentifiedArrayOf<Book>()
        public var lastYearBooks = IdentifiedArrayOf<Book>()
        public var randomBooks = IdentifiedArrayOf<Book>()
        public var isLoading = false
        @PresentationState public var destination: Destination.State?

        public init(
            latestBooks: IdentifiedArrayOf<Book> = IdentifiedArrayOf<Book>(),
            lastYearBooks: IdentifiedArrayOf<Book> = IdentifiedArrayOf<Book>(),
            randomBooks: IdentifiedArrayOf<Book> = IdentifiedArrayOf<Book>(),
            isLoading: Bool = false,
            destination: Destination.State? = nil
        ) {
            self.latestBooks = latestBooks
            self.lastYearBooks = lastYearBooks
            self.randomBooks = randomBooks
            self.isLoading = isLoading
            self.destination = destination
        }
    }

    public enum Action {
        /// メニュー内の「お気に入り」をタップした時の `Action`.
        case favoritesButtonTapped
        /// 画面遷移用の `Reducer` に伝える `Action`.
        case destination(PresentationAction<Destination.Action>)
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
        /// ヘッダーのランダムな作品一覧がタップされた時の `Action`.
        case randomBookTapped(Int)
        /// 画面に必要な情報が全て返ってきた時の `Action`.
        case response(Result<Response, Error>)
        /// メニュー内の「検索」をタップした時の `Action`.
        case searchButtonTapped
        /// 非同期処理を実行するための `Action`.
        case task
    }

    public struct Response {
        let latestBooks: [Book]
        let lastYearBooks: [Book]
        let randomBooks: [Book]

        public init(
            latestBooks: [Book],
            lastYearBooks: [Book],
            randomBooks: [Book]
        ) {
            self.randomBooks = randomBooks
            self.latestBooks = latestBooks
            self.lastYearBooks = lastYearBooks
        }
    }

    @Dependency(\.authClient) var authClient
    @Dependency(\.date) var dateGenerator
    @Dependency(\.firestoreClient) var firestoreClient
    @Dependency(\.randomDateGenerator) var randomDateGenerator

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .favoritesButtonTapped:
                state.destination = .favorites(
                    FavoritesFeature.State()
                )

                return .none
            case .destination:

                return .none
            case let .latestBookTapped(index):
                state.destination = .viewer(
                    ViewerFeature.State(
                        source: .book(state.latestBooks[index])
                    )
                )

                return .none
            case .latestBookMoreTapped:
                state.destination = .bookshelf(
                    BookshelfFeature.State(
                        collection: .latest
                    )
                )

                return .none
            case let .lastYearBookTapped(index):
                state.destination = .viewer(
                    ViewerFeature.State(
                        source: .book(state.lastYearBooks[index])
                    )
                )

                return .none
            case .lastYearBookMoreTapped:
                state.destination = .bookshelf(
                    BookshelfFeature.State(
                        collection: .lastYear
                    )
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
            case let .randomBookTapped(index):
                state.destination = .viewer(
                    ViewerFeature.State(
                        source: .book(state.randomBooks[index])
                    )
                )

                return .none
            case let .response(.success(response)):
                state.latestBooks = IdentifiedArray(uniqueElements: response.latestBooks)
                state.lastYearBooks = IdentifiedArray(uniqueElements: response.lastYearBooks)
                state.randomBooks = IdentifiedArray(uniqueElements: response.randomBooks)
                state.isLoading = false

                return .none
            case .response(.failure):
                state.isLoading = false

                return .none
            case .searchButtonTapped:
                state.destination = .search(
                    SearchFeature.State()
                )

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
        .ifLet(\.$destination, action: \.destination) {
            Destination()
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
                afterDate: now,
                limit: 6
            )
        )
        async let fetchLastYearBooksTask = firestoreClient.fetchLatestBooks(
            FirestoreClient.LatestBooksRequest(
                afterDate: now.lastYear,
                limit: 6
            )
        )
        async let fetchRandomBooksTask = firestoreClient.fetchLatestBooks(
            FirestoreClient.LatestBooksRequest(
                afterDate: randomDateGenerator.sinceServiceLaunched(),
                limit: 3
            )
        )

        let results = try await (fetchLatestBooksTask, fetchLastYearBooksTask, fetchRandomBooksTask)
        return Response(
            latestBooks: results.0,
            lastYearBooks: results.1,
            randomBooks: results.2
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
                                pageViewConfigurations: viewStore.randomBooks.map {
                                    .init(
                                        id: $0.id, 
                                        title: $0.title,
                                        imageURL: $0.thumbnailURL
                                    )
                                }
                            ) { index in
                                viewStore.send(.randomBookTapped(index))
                            }

                            GalleryMenuView {
                                viewStore.send(.searchButtonTapped)
                            } scrapingAction: {
                                // TODO
                            } favoriteAction: {
                                viewStore.send(.favoritesButtonTapped)
                            }

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
            .fullScreenCover(
                store: store.scope(
                    state: \.$destination.bookshelf,
                    action: \.destination.bookshelf
                )
            ) { store in
                NavigationStack {
                    BookshelfView(store: store)
                }
            }
            .fullScreenCover(
                store: store.scope(
                    state: \.$destination.favorites,
                    action: \.destination.favorites
                )
            ) { store in
                NavigationStack {
                    FavoritesView(store: store)
                }
            }
            .fullScreenCover(
                store: store.scope(
                    state: \.$destination.search,
                    action: \.destination.search
                )
            ) { store in
                NavigationStack {
                    SearchView(store: store)
                }
            }
            .fullScreenCover(
                store: store.scope(
                    state: \.$destination.viewer,
                    action: \.destination.viewer
                )
            ) { store in
                NavigationStack {
                    ViewerView(store: store)
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
            $0.authClient.uid = { "" }
            $0.firestoreClient.fetchLatestBooks = { _ in booksStub }
            $0.firestoreClient.fetchCertainDateBooks = { _ in booksStub }
        }
    )
}
#endif

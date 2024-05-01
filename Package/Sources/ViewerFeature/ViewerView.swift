//
//  ViewerView.swift
//
//
//  Created by Shunya Yamada on 2024/02/10.
//

import AuthClient
import BookFeature
import ComposableArchitecture
import FirestoreClient
import NukeUI
import SharedModels
import SwiftUI
import SwiftUIPager

// MARK: - Reducer

@Reducer
public struct ViewerFeature {
    @Reducer
    public struct Destination {
        public enum State: Equatable {
            case book(BookFeature.State)
        }

        public enum Action {
            case book(BookFeature.Action)
        }

        public var body: some ReducerOf<Self> {
            Scope(state: \.book, action: \.book) {
                BookFeature()
            }
        }
    }

    public struct State: Equatable {
        /// ビューワーで表示するソース.
        var source: Source
        /// ビューワーで表示する本のデータ.
        var book: Book?
        /// Pager で表示しているページのインデックス.
        var pageIndex: Int
        /// スライダーで表示しているページ数.
        var sliderValue: Double
        /// ビューワーで表示している作品がお気に入り済みかどうか.
        var isFavorite = false
        /// ビューワーで表示している作品がお気に入り済みかの処理が実行中かどうか.
        var isFavoriteLoading = false
        /// ビューワーに表示する作品を読み込む処理が実行中かどうか.
        var isLoading = false
        /// 画面遷移用の `State`.
        @PresentationState var destination: Destination.State?

        public init(
            source: Source,
            isFavorite: Bool = false,
            isFavoriteLoading: Bool = false,
            isLoading: Bool = false,
            destination: Destination.State? = nil
        ) {
            self.source = source
            // 既に取得済みの本を表示する場合でも画面表示後にデータを入れるので一旦 `nil` を入れておく.
            self.book = nil
            self.pageIndex = 0
            self.sliderValue = 1
            self.isFavorite = isFavorite
            self.isFavoriteLoading = isFavoriteLoading
            self.isLoading = isLoading
            self.destination = destination
        }
    }

    public enum Action {
        /// 閉じるボタンタップ時の `Action`.
        case closeButtonTapped
        /// 画面遷移用の `Action`.
        case destination(PresentationAction<Destination.Action>)
        /// お気に入りボタンタップ時の `Action`.
        case favoriteButtonTapped
        /// 作品詳細ボタンタップ時の `Action`.
        case informationButtonTapped
        /// Pager のページが切り替わった時の `Action`.
        case pageChanged(Int)
        /// 非同期処理完了後の `Action`.
        case response(Result<Response, Error>)
        /// スライダーの値が変化した時の `Action`.
        case sliderValueChanged(Double)
        /// 画面表示時の非同期処理を実行する `Action`.
        case task
        /// お気に入り状態の切り替え処理完了後の `Action`.
        case toggleIsFavoriteResponse(Result<Bool, Error>)
    }

    /// ビューワーで表示する本のソース.
    @CasePathable
    @dynamicMemberLookup
    public enum Source: Equatable {
        /// ギャラリーなどで表示している本.
        case book(Book)
        /// お気に入り一覧で表示しているお気に入り済みの本.
        case favoriteBook(FavoriteBook)
    }
    
    /// 画面表示時の非同期処理の結果をまとめたレスポンス.
    public struct Response {
        public let book: Book
        public let isFavorite: Bool

        public init(
            book: Book,
            isFavorite: Bool
        ) {
            self.book = book
            self.isFavorite = isFavorite
        }
    }

    @Dependency(\.authClient) var authClient
    @Dependency(\.date) var dateGenerator
    @Dependency(\.dismiss) var dismiss
    @Dependency(\.firestoreClient) var firestoreClient

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .closeButtonTapped:
                return .run { _ in
                    await self.dismiss()
                }
            case .destination:

                return .none
            case .favoriteButtonTapped:
                guard let uid = self.authClient.uid(),
                      let book = state.book else {
                    return .none
                }
                state.isFavoriteLoading = true

                return .run { [state] send in
                    await send(
                        .toggleIsFavoriteResponse(
                            Result {
                                try await toggleFavorite(
                                    uid: uid,
                                    book: book,
                                    isFavorite: state.isFavorite
                                )
                            }
                        )
                    )
                }
            case .informationButtonTapped:
                guard let book = state.book else {
                    return .none
                }

                state.destination = .book(
                    BookFeature.State(
                        book: book
                    )
                )

                return .none
            case let .pageChanged(pageIndex):
                guard let imageURLsCount = state.book?.imageURLs.count else {
                    return .none
                }
                state.pageIndex = pageIndex
                state.sliderValue = Double(imageURLsCount - 1) - Double(pageIndex)

                return .none
            case let .response(.success(response)):
                state.book = response.book
                state.isFavorite = response.isFavorite
                state.pageIndex = 0
                state.sliderValue = Double((response.book.imageURLs.count) - 1)
                state.isLoading = false

                return .none
            case let .response(.failure(error)):
                state.isLoading = false
                print(error)

                return .none
            case let .sliderValueChanged(value):
                guard let imageURLsCount = state.book?.imageURLs.count else {
                    return .none
                }
                state.pageIndex = (imageURLsCount - 1) - Int(value)
                state.sliderValue = value

                return .none
            case .task:
                guard let uid = self.authClient.uid() else {
                    return .none
                }
                state.isLoading = true

                return .run { [state] send in
                    await send(
                        .response(
                            Result {
                                // お気に入り済みの本を表示する場合は本のデータを取得する.
                                let book = try await fetchBook(for: state.source)
                                // お気に入り状態を取得する.
                                let isExists = try await firestoreClient.favoriteBookExists(
                                    FirestoreClient.FavoriteBookExistsRequest(
                                        userID: uid,
                                        bookID: book.id
                                    )
                                )
                                return Response(
                                    book: book,
                                    isFavorite: isExists
                                )
                            }
                        )
                    )
                }
            case let .toggleIsFavoriteResponse(.success(isFavorite)):
                state.isFavoriteLoading = false
                state.isFavorite = isFavorite

                return .none
            case let .toggleIsFavoriteResponse(.failure(error)):
                state.isFavoriteLoading = false
                print(error)

                return .none
            }
        }
        .ifLet(\.$destination, action: \.destination) {
            Destination()
        }
    }

    public init() {}
}

private extension ViewerFeature {
    /// ソースに応じて本データを取得する.
    /// - Parameter source: ソースの種類.
    /// - Returns: 取得した本のデータ.
    func fetchBook(for source: Source) async throws -> Book {
        switch source {
        case let .book(book):
            return book
        case let .favoriteBook(favoriteBook):
            return try await firestoreClient.fetchBook(favoriteBook.id ?? "")
        }
    }

    /// 作品のお気に入り状態を切り替える.
    /// - Parameters:
    ///   - uid: サインイン中のユーザー ID.
    ///   - book: お気に入り対象の作品のデータ.
    ///   - isFavorite: お気に入りにするかどうかのフラグ.
    /// - Returns: 切り替え後のお気に入り状態.
    func toggleFavorite(
        uid: String,
        book: Book,
        isFavorite: Bool
    ) async throws -> Bool {
        if isFavorite {
            try await firestoreClient.removeFavoriteBook(
                FirestoreClient.RemoveFavoriteBookRequest(
                    userID: uid,
                    bookID: book.id
                )
            )
            return false
        } else {
            try await firestoreClient.addFavoriteBook(
                FirestoreClient.AddFavoriteBookRequest(
                    userID: uid,
                    favoriteBook: FavoriteBook(
                        book: book,
                        createdAt: dateGenerator.now
                    )
                )
            )
            return true
        }
    }
}

extension FavoriteBook {
    init(
        book: Book,
        createdAt: Date
    ) {
        self.init(
            id: book.id ?? "",
            title: book.title,
            createdAt: createdAt,
            publishedAt: book.createdAt,
            thumbnailURL: book.thumbnailURL
        )
    }
}

// MARK: - View

public struct ViewerView: View {
    let store: StoreOf<ViewerFeature>

    public var body: some View {
        WithViewStore(store, observe: { $0 }) { viewStore in
            if !viewStore.isLoading,
               let book = viewStore.state.book {
                ZStack(alignment: .bottom) {
                    Pager(
                        page: Page.withIndex(viewStore.pageIndex),
                        data: makeConfigurations(fromImageURLs: book.imageURLs)
                    ) { configuration in
                        ViewerPageView(configuration: configuration)
                    }
                    .onPageChanged { pageIndex in
                        viewStore.send(.pageChanged(pageIndex))
                    }
                    .horizontal(.endToStart)
                    .itemAspectRatio(1)

                    HStack(spacing: 8) {
                        if viewStore.isFavoriteLoading {
                            ProgressView()
                                .frame(width: 24, height: 24)
                        } else {
                            ViewerFavoriteButton(isFavorite: viewStore.isFavorite) {
                                viewStore.send(.favoriteButtonTapped)
                            }
                        }

                        Slider(
                            value: viewStore.binding(get: \.sliderValue, send: { .sliderValueChanged($0) }),
                            in: 0...Double(book.imageURLs.count - 1),
                            step: 1
                        )

                        Button {
                            viewStore.send(.informationButtonTapped)
                        } label: {
                            Image(systemName: "info.circle")
                                .frame(width: 24, height: 24)
                        }
                    }
                    .padding()
                }
                .navigationTitle(book.title)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button(action: {
                            viewStore.send(.closeButtonTapped)
                        }, label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(Color(.systemGray3))
                        })
                    }
                }
            } else {
                ProgressView()
            }
        }
        .task {
            store.send(.task)
        }
        .sheet(
            store: store.scope(
                state: \.$destination.book,
                action: \.destination.book
            )
        ) { store in
            NavigationStack {
                BookView(store: store)
            }
        }
    }

    public init(store: StoreOf<ViewerFeature>) {
        self.store = store
    }
}

private extension ViewerView {
    func makeConfigurations(fromImageURLs imageURLs: [String]) -> [ViewerPageView.Configuration] {
        imageURLs
            .compactMap { URL(string: $0) }
            .map {
                ViewerPageView.Configuration(
                    id: $0.absoluteString,
                    imageURL: $0
                )
            }
    }
}

#if DEBUG
#Preview {
    ViewerView(
        store: Store(
            initialState: ViewerFeature.State(
                source: .book(
                    Book(
                        id: UUID().uuidString,
                        title: "プレビュー",
                        url: "https://avatars.githubusercontent.com/u/31949692?v=4",
                        createdAt: Date(),
                        imageURLs: [
                            "https://avatars.githubusercontent.com/u/31949692?v=4",
                            "https://avatars.githubusercontent.com/u/31949692?v=3",
                            "https://avatars.githubusercontent.com/u/31949692?v=2"
                        ],
                        categories: [
                            "プレビュー"
                        ],
                        author: nil,
                        thumbnailURL: "https://avatars.githubusercontent.com/u/31949692?v=4"
                    )
                )
            )
        ) {
            ViewerFeature()
        }
    )
}
#endif

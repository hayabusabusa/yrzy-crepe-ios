//
//  FavoritesView.swift
//
//
//  Created by Shunya Yamada on 2024/02/25.
//

import AuthClient
import ComposableArchitecture
import FirestoreClient
import SharedExtensions
import SharedModels
import SwiftUI
import ViewerFeature

// MARK: - Reducer

@Reducer
public struct FavoritesFeature {
    /// 画面遷移用の子 `Reducer`.
    @Reducer
    public struct Destination {
        public enum State: Equatable {
            case viewer(ViewerFeature.State)
        }

        public enum Action {
            case viewer(ViewerFeature.Action)
        }

        public var body: some ReducerOf<Self> {
            Scope(state: \.viewer, action: \.viewer) {
                ViewerFeature()
            }
        }
    }

    public struct State: Equatable {
        public var books = IdentifiedArrayOf<FavoriteBook>()
        public var isLoading = false
        public var isPaginationLoading = false
        @PresentationState public var destination: Destination.State?

        public init(
            books: IdentifiedArrayOf<FavoriteBook> = IdentifiedArrayOf<FavoriteBook>(),
            isLoading: Bool = false,
            isPaginationLoading: Bool = false,
            destination: Destination.State? = nil
        ) {
            self.books = books
            self.isLoading = isLoading
            self.isPaginationLoading = isPaginationLoading
            self.destination = destination
        }
    }

    public enum Action {
        /// 一覧のアイテムがタップされた時の `Action`.
        case bookTapped(Int)
        /// 閉じるボタンタップ時の `Action`.
        case closeButtonTapped
        /// 画面遷移用の `Action`.
        case destination(PresentationAction<Destination.Action>)
        /// `ScrollView` 内のアイテムが表示された時の `Action`.
        case onAppearScrollViewContent(Int)
        /// 追加読み込みの非同期処理が完了した後の `Action`.
        case paginationResponse(Result<[FavoriteBook], Error>)
        /// 非同期処理完了時の `Action`.
        case response(Result<[FavoriteBook], Error>)
        /// 非同期処理実行用の `Action`.
        case task
    }

    @Dependency(\.authClient) var authClient
    @Dependency(\.date) var dateGenerator
    @Dependency(\.dismiss) var dismiss
    @Dependency(\.firestoreClient) var firestoreClient

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case let .bookTapped(index):
                state.destination = .viewer(
                    ViewerFeature.State(
                        source: .favoriteBook(state.books[index])
                    )
                )

                return .none
            case .closeButtonTapped:

                return .run { _ in
                    await dismiss()
                }
            case .destination:
                
                return .none
            case let .onAppearScrollViewContent(offset):
                // 既に追加ロード中の場合は何もしない.
                guard !state.isPaginationLoading,
                      let uid = authClient.uid() else {
                    return .none
                }

                let threshold = 3
                let scrolledOffset = (state.books.count - 1) - offset
                let needsPagination = scrolledOffset <= threshold

                // 追加ロードが発生する位置までスクロールされていない場合は何もしない.
                guard needsPagination else {
                    return .none
                }

                state.isPaginationLoading = true
                return .run { [state] send in
                    await send(
                        .paginationResponse(
                            Result {
                                try await firestoreClient.fetchLatestFavoriteBooks(
                                    FirestoreClient.LatestFavoriteBookRequest(
                                        userID: uid,
                                        orderBy: "createdAt",
                                        isDescending: true,
                                        afterDate: state.books.last?.createdAt ?? Date(),
                                        limit: 15
                                    )
                                )
                            }
                        )
                    )
                }
            case let .paginationResponse(.success(books)):
                state.books.append(contentsOf: books)
                state.isPaginationLoading = false

                return .none
            case let .paginationResponse(.failure(error)):
                state.isPaginationLoading = false
                print(error)

                return .none
            case let .response(.success(books)):
                state.isLoading = false
                state.books = IdentifiedArray(uniqueElements: books)

                return .none
            case let .response(.failure(error)):
                state.isLoading = false
                print(error)

                return .none
            case .task:
                guard let uid = self.authClient.uid() else {
                    return .none
                }
                state.isLoading = true

                return .run { send in
                    await send(
                        .response(
                            Result {
                                try await firestoreClient.fetchLatestFavoriteBooks(
                                    FirestoreClient.LatestFavoriteBookRequest(
                                        userID: uid,
                                        orderBy: "createdAt",
                                        isDescending: true,
                                        afterDate: dateGenerator.now,
                                        limit: 15
                                    )
                                )
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

// MARK: - View

public struct FavoritesView: View {
    let store: StoreOf<FavoritesFeature>

    public var body: some View {
        WithViewStore(store, observe: { $0 }) { viewStore in
            if viewStore.isLoading {
                ProgressView()
            } else {
                ScrollView {
                    LazyVStack {
                        ForEach(
                            Array(makeConfigurations(from: viewStore.books).enumerated()),
                            id: \.offset
                        ) { index, configuration in
                            FavoritesItemView(configuration: configuration) {
                                viewStore.send(.bookTapped(index))
                            }
                            .onAppear {
                                viewStore.send(.onAppearScrollViewContent(index))
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("お気に入り一覧")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(action: {
                    store.send(.closeButtonTapped)
                }, label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(Color(.systemGray3))
                })
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

    public init(store: StoreOf<FavoritesFeature>) {
        self.store = store
    }
}

private extension FavoritesView {
    func makeConfigurations(from books: IdentifiedArrayOf<FavoriteBook>) -> [FavoritesItemView.Configuration] {
        books.map { book in
            FavoritesItemView.Configuration(
                title: book.title,
                date: book.createdAt.string(for: .short),
                imageURL: book.thumbnailURL
            )
        }
    }
}

// MARK: - Preview

#if DEBUG
let booksStub = Array(repeating: 0, count: 10)
    .map { _ in
        FavoriteBook(
            id: UUID().uuidString,
            title: "TEST",
            createdAt: Date(),
            publishedAt: Date(),
            thumbnailURL: "https://avatars.githubusercontent.com/u/31949692?v=4"
        )
    }

#Preview {
    FavoritesView(
        store: Store(initialState: FavoritesFeature.State()) {
            FavoritesFeature()
        } withDependencies: {
            $0.authClient.isSignIn = { true }
            $0.authClient.uid = { "" }
            $0.firestoreClient.fetchLatestFavoriteBooks = { _ in booksStub }
        }
    )
}
#endif

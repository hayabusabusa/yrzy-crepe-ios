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
        @PresentationState public var destination: Destination.State?

        public init(
            books: IdentifiedArrayOf<FavoriteBook> = IdentifiedArrayOf<FavoriteBook>(),
            isLoading: Bool = false,
            destination: Destination.State? = nil
        ) {
            self.books = books
            self.isLoading = isLoading
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
                print(state.books[index])
//                state.destination = .viewer(
//                    ViewerFeature.State(book: <#T##Book#>)
//                )

                return .none
            case .closeButtonTapped:

                return .run { _ in
                    await dismiss()
                }
            case .destination:
                
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
                                        limit: 10
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

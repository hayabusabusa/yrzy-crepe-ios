//
//  BookshelfView.swift
//
//
//  Created by Shunya Yamada on 2024/02/15.
//

import ComposableArchitecture
import FirestoreClient
import NukeUI
import SharedExtensions
import SharedModels
import SwiftUI
import ViewerFeature

// MARK: - Reducer

@Reducer
public struct BookshelfFeature {
    public struct State: Equatable {
        public let collection: Collection
        public var books = IdentifiedArrayOf<Book>()
        public var isLoading = false
        public var isPaginationLoading = false
        @PresentationState public var viewer: ViewerFeature.State?

        public init(
            collection: Collection,
            books: IdentifiedArrayOf<Book> = IdentifiedArrayOf<Book>(),
            isLoading: Bool = false,
            isPaginationLoading: Bool = false,
            viewer: ViewerFeature.State? = nil
        ) {
            self.collection = collection
            self.books = books
            self.isLoading = isLoading
            self.isPaginationLoading = isPaginationLoading
            self.viewer = viewer
        }
    }

    public enum Action {
        /// 一覧の本タップ時の `Action`.
        case bookTapped(Int)
        /// 閉じるボタンタップ時の `Action`.
        case closeButtonTapped
        /// `ScrollView` 内のアイテムが表示された時の `Action`.
        case onAppearScrollViewContent(Int)
        /// 追加読み込みの非同期処理が完了した後の `Action`.
        case paginationResponse(Result<[Book], Error>)
        /// 画面表示時の非同期処理が完了した後の `Action`.
        case response(Result<[Book], Error>)
        /// 画面表示時の非同期処理を実行するための `Action`.
        case task
        /// ビューワー画面に遷移する `Action`.
        case viewer(PresentationAction<ViewerFeature.Action>)
    }

    /// 本一覧の種類.
    public enum Collection {
        /// 最新の本一覧.
        case latest
        /// 1年前に追加された本一覧.
        case lastYear
    }

    @Dependency(\.date) var dateGenerator
    @Dependency(\.dismiss) var dismiss
    @Dependency(\.firestoreClient) var firestoreClient

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case let .bookTapped(index):
                state.viewer = ViewerFeature.State(
                    book: state.books[index]
                )

                return .none
            case .closeButtonTapped:

                return .run { _ in
                    await self.dismiss()
                }
            case let .onAppearScrollViewContent(offset):
                // 既に追加ロード中の場合は何もしない.
                guard !state.isPaginationLoading else {
                    return .none
                }

                let threshold = 1
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
                                try await fetchNextBooks(
                                    for: state.collection,
                                    lastDate: state.books.last?.createdAt ?? Date()
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
                print(error)
                state.isPaginationLoading = false

                return .none
            case let .response(.success(books)):
                state.books = IdentifiedArray(uniqueElements: books)

                return .none
            case let .response(.failure(error)):
                print(error)

                return .none
            case .task:

                return .run { [collection = state.collection] send in
                    await send(
                        .response(
                            Result {
                                try await fetchBooks(for: collection)
                            }
                        )
                    )
                }
            case .viewer:

                return .none
            }
        }
        .ifLet(\.$viewer, action: \.viewer) {
            ViewerFeature()
        }
    }

    public init() {}
}

private extension BookshelfFeature {
    /// 本一覧を Firestore から取得する.
    /// - Parameter collection: 本一覧の種類.
    /// - Returns: 本一覧.
    func fetchBooks(for collection: Collection) async throws -> [Book] {
        let now = dateGenerator.now
        switch collection {
        case .latest:
            return try await firestoreClient.fetchLatestBooks(
                FirestoreClient.LatestBooksRequest(
                    orderBy: "createdAt",
                    isDescending: true,
                    afterDate: now,
                    limit: 10
                )
            )
        case .lastYear:
            return try await firestoreClient.fetchCertainDateBooks(
                FirestoreClient.CertainDateBooksRequest(
                    date: now.lastYear,
                    isDescending: true,
                    limit: 10
                )
            )
        }
    }
    
    /// 追加の本一覧を取得する.
    /// - Parameters:
    ///   - collection: 本一覧の種類.
    ///   - lastDate: 一覧に表示している本一覧 最後の要素の日付.
    /// - Returns: 本一覧.
    func fetchNextBooks(
        for collection: Collection,
        lastDate: Date
    ) async throws -> [Book] {
        switch collection {
        case .latest:
            return try await firestoreClient.fetchLatestBooks(
                FirestoreClient.LatestBooksRequest(
                    orderBy: "createdAt",
                    isDescending: true,
                    afterDate: lastDate,
                    limit: 10
                )
            )
        case .lastYear:
            return try await firestoreClient.fetchCertainDateBooks(
                FirestoreClient.CertainDateBooksRequest(
                    date: lastDate,
                    isDescending: true,
                    limit: 10
                )
            )
        }
    }
}

// MARK: - View

public struct BookshelfView: View {
    let store: StoreOf<BookshelfFeature>

    public var body: some View {
        WithViewStore(store, observe: { $0 }) { viewStore in
            ScrollView {
                LazyVStack {
                    ForEach(Array(viewStore.books.enumerated()), id: \.offset) { enumerated in
                        BookshelfItemView(
                            configuration: BookshelfItemView.Configuration(
                                title: enumerated.element.title,
                                imageURL: enumerated.element.thumbnailURL,
                                createdAt: nil
                            )
                        ) {
                            viewStore.send(.bookTapped(enumerated.offset))
                        }
                        .onAppear {
                            viewStore.send(.onAppearScrollViewContent(enumerated.offset))
                        }
                    }
                }
            }
            .navigationTitle(title(for: viewStore.collection))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: {
                        viewStore.send(.closeButtonTapped)
                    }, label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(Color(uiColor: .systemGray.withAlphaComponent(0.3)))
                    })
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
        }
    }

    public init(store: StoreOf<BookshelfFeature>) {
        self.store = store
    }
}

private extension BookshelfView {
    func title(for collection: BookshelfFeature.Collection) -> String {
        switch collection {
        case .latest:
            "最近追加された作品"
        case .lastYear:
            "1年前に追加された作品"
        }
    }
}

// MARK: - Preview

#if DEBUG
#Preview {
    BookshelfView(
        store: Store(
            initialState: BookshelfFeature.State(
                collection: .latest
            )
        ) {
            BookshelfFeature()
        }
    )
}
#endif

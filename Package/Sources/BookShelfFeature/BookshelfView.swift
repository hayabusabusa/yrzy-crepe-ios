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

// MARK: - Reducer

@Reducer
public struct BookshelfFeature {
    public struct State: Equatable {
        public let collection: Collection
        public var books = IdentifiedArrayOf<Book>()
        public var isLoading = false

        public init(
            collection: Collection,
            books: IdentifiedArrayOf<Book> = IdentifiedArrayOf<Book>(),
            isLoading: Bool = false
        ) {
            self.collection = collection
            self.books = books
            self.isLoading = isLoading
        }
    }

    public enum Action {
        /// 閉じるボタンタップ時の `Action`.
        case closeButtonTapped
        /// 画面表示時の非同期処理が完了した後の `Action`.
        case response(Result<[Book], Error>)
        /// 画面表示時の非同期処理を実行するための `Action`.
        case task
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
            case .closeButtonTapped:

                return .run { _ in
                    await self.dismiss()
                }
            case let .response(.success(books)):
                state.books = IdentifiedArray(uniqueElements: books)

                return .none
            case let .response(.failure(error)):
                print(error)

                return .none
            case .task:

                let collection = state.collection
                return .run { send in
                    await send(
                        .response(
                            Result {
                                try await fetchBooks(for: collection)
                            }
                        )
                    )
                }
            }
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
}

// MARK: - View

public struct BookshelfView: View {
    let store: StoreOf<BookshelfFeature>

    public var body: some View {
        WithViewStore(store, observe: { $0 }) { viewStore in
            ScrollView {
                ForEach(viewStore.books) { book in
                    BookshelfItemView(
                        configuration: BookshelfItemView.Configuration(
                            title: book.title,
                            imageURL: book.thumbnailURL,
                            createdAt: nil
                        )
                    )
                }
            }
            .background {
                GeometryReader { proxy in
                    Color.clear
                        .onChange(of: proxy.frame(in: .named("ScrollView")).minY) { offset in
                            print(proxy.size, offset)
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

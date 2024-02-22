//
//  ViewerView.swift
//
//
//  Created by Shunya Yamada on 2024/02/10.
//

import AuthClient
import ComposableArchitecture
import FirestoreClient
import NukeUI
import SharedModels
import SwiftUI
import SwiftUIPager

// MARK: - Reducer

@Reducer
public struct ViewerFeature {
    public struct State: Equatable {
        /// ビューワーで表示している作品のデータ.
        ///
        /// 今後 ID 経由で作品を取れるようにする.
        var book: Book
        /// Pager で表示しているページのインデックス.
        var pageIndex: Int
        /// スライダーで表示しているページ数.
        var sliderValue: Double
        /// ビューワーで表示している作品がお気に入り済みかどうか.
        var isFavorite = false
        /// ビューワーで表示している作品がお気に入り済みかの処理が実行中かどうか.
        var isFavoriteLoading = false

        public init(
            book: Book,
            isFavorite: Bool = false,
            isFavoriteLoading: Bool = false
        ) {
            self.book = book
            self.pageIndex = 0
            self.sliderValue = Double(book.imageURLs.count - 1)
            self.isFavorite = isFavorite
            self.isFavoriteLoading = isFavoriteLoading
        }
    }

    public enum Action {
        /// 閉じるボタンタップ時の `Action`.
        case closeButtonTapped
        /// Pager のページが切り替わった時の `Action`.
        case pageChanged(Int)
        /// 非同期処理完了後の `Action`.
        case response(Result<Response, Error>)
        /// スライダーの値が変化した時の `Action`.
        case sliderValueChanged(Double)
        /// 画面表示時の非同期処理を実行する `Action`.
        case task
        /// お気に入りボタンタップ時の `Action`.
        case favoriteButtonTapped
    }

    public struct Response {
        public let isFavorite: Bool

        public init(isFavorite: Bool) {
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
            case let .pageChanged(pageIndex):
                state.pageIndex = pageIndex
                state.sliderValue = Double(state.book.imageURLs.count - 1) - Double(pageIndex)

                return .none
            case let .response(.success(response)):
                state.isFavoriteLoading = false
                state.isFavorite = response.isFavorite

                return .none
            case let .response(.failure(error)):
                print(error)

                return .none
            case let .sliderValueChanged(value):
                state.pageIndex = (state.book.imageURLs.count - 1) - Int(value)
                state.sliderValue = value

                return .none
            case .task:
                guard let uid = self.authClient.uid() else {
                    return .none
                }
                state.isFavoriteLoading = true

                return .run { [state] send in
                    await send(
                        .response(
                            Result {
                                let isExists = try await self.firestoreClient.favoriteBookExists(
                                    FirestoreClient.FavoriteBookExistsRequest(
                                        userID: uid,
                                        bookID: state.book.id
                                    )
                                )
                                return Response(isFavorite: isExists)
                            }
                        )
                    )
                }
            case .favoriteButtonTapped:
                guard let uid = self.authClient.uid() else {
                    return .none
                }
                state.isFavoriteLoading = true

                return .run { [state] send in
                    await send(
                        .response(
                            Result {
                                if state.isFavorite {
                                    try await self.firestoreClient.removeFavoriteBook(
                                        FirestoreClient.RemoveFavoriteBookRequest(
                                            userID: uid,
                                            bookID: state.book.id
                                        )
                                    )
                                    return Response(isFavorite: false)
                                } else {
                                    try await self.firestoreClient.addFavoriteBook(
                                        FirestoreClient.AddFavoriteBookRequest(
                                            userID: uid,
                                            favoriteBook: FavoriteBook(
                                                book: state.book,
                                                createdAt: dateGenerator.now
                                            )
                                        )
                                    )
                                    return Response(isFavorite: true)
                                }
                            }
                        )
                    )
                }
            }
        }
    }

    public init() {}
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
            ZStack(alignment: .bottom) {
                Pager(
                    page: Page.withIndex(viewStore.pageIndex),
                    data: makeConfigurations(fromImageURLs: viewStore.book.imageURLs)
                ) { configuration in
                    ViewerPageView(configuration: configuration)
                }
                .onPageChanged { pageIndex in
                    viewStore.send(.pageChanged(pageIndex))
                }
                .horizontal(.endToStart)
                .itemAspectRatio(1)

                HStack {
                    if viewStore.isFavoriteLoading {
                        ProgressView()
                            .frame(width: 24, height: 24)
                    } else {
                        ViewerFavoriteButton(isFavorite: viewStore.isFavorite) {
                            viewStore.send(.favoriteButtonTapped)
                        }
                    }

                    Spacer()
                        .frame(width: 8)

                    Slider(
                        value: viewStore.binding(get: \.sliderValue, send: { .sliderValueChanged($0) }),
                        in: 0...Double(viewStore.book.imageURLs.count - 1),
                        step: 1
                    )
                }
                .padding()
            }
            .navigationTitle(viewStore.book.title)
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
            .task {
                viewStore.send(.task)
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
                book: Book(
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
        ) {
            ViewerFeature()
        }
    )
}
#endif

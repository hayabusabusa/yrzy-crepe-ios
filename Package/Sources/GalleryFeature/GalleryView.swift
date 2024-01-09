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
    }

    public enum Action {
        /// 画面に必要な情報が全て返ってきた時の `Action`.
        case allResponse(Result<[Book], Error>)
        /// 認証済みかどうか確認する `Action`.
        case auth(Bool)
        /// 匿名認証を行う `Action`.
        case signIn
        /// 匿名認証の結果が返ってきた時の `Action`.
        case signInResponse(Result<User, Error>)
        /// 非同期処理を実行するための `Action`.
        case task
    }

    @Dependency(\.authClient) var authClient
    @Dependency(\.date) var dateGenerator
    @Dependency(\.firestoreClient) var firestoreClient

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case let .allResponse(.success(books)):
                state.books = IdentifiedArray(uniqueElements: books)
                state.isLoading = false

                return .none
            case .allResponse(.failure):
                state.isLoading = false

                return .none
            case let .auth(isSignIn):
                if isSignIn {
                    return .run { send in
                        await send(
                            .allResponse(
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
                } else {
                    return .send(.signIn)
                }
            case .signIn:
                return .run { send in
                    await send(
                        .signInResponse(
                            Result {
                                try await self.authClient.signInAsAnonymousUser()
                            }
                        )
                    )
                }
            case .signInResponse(.success):
                return .run { send in
                    await send(
                        .allResponse(
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
            case let .signInResponse(.failure(error)):
                print(error)

                return .none
            case .task:
                state.isLoading = true

                return .send(.auth(authClient.isSignIn()))
            }
        }
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
                    List {
                        ForEach(viewStore.books) { book in
                            HStack {
                                LazyImage(url: book.thumbnailURL.flatMap { URL(string: $0) }) { state in
                                    if let image = state.image {
                                        image
                                            .resizable()
                                            .aspectRatio(contentMode: .fill)
                                            .frame(width: 44, height: 44)
                                    } else {
                                        Color(.secondarySystemBackground)
                                    }
                                }
                                Text(book.title)
                            }
                        }
                    }
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
            $0.authClient.isSignIn = {
                true
            }
            $0.firestoreClient.fetchLatestBooks = { _ in
                [
                    .init(id: UUID().uuidString,
                          title: "TEST",
                          url: "",
                          createdAt: Date(),
                          imageURLs: [],
                          categories: [],
                          author: nil,
                          thumbnailURL: "https://avatars.githubusercontent.com/u/31949692?v=4")
                ]
            }
        }
    )
}
#endif

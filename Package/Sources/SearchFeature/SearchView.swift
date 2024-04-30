//
//  SearchView.swift
//
//
//  Created by Shunya Yamada on 2024/02/24.
//

import ComposableArchitecture
import FirestoreClient
import SharedExtensions
import SharedModels
import SharedViews
import SwiftUI

// MARK: - Reducer

@Reducer
public struct SearchFeature {
    /// 画面遷移用の子 `Reducer`.
    @Reducer
    public struct Destination {
        public enum State: Equatable {
            case form(SearchForm.State)
        }

        public enum Action {
            case form(SearchForm.Action)
        }

        public var body: some ReducerOf<Self> {
            Scope(state: \.form, action: \.form) {
                SearchForm()
            }
        }

        public init() {}
    }

    public struct State: Equatable {
        public var books = IdentifiedArrayOf<Book>()
        public var text = ""
        public var selectedDate = Date()
        public var suggestedTokens = IdentifiedArrayOf<SearchToken>()
        public var tokens = IdentifiedArrayOf<SearchToken>()
        @PresentationState public var destination: Destination.State?

        public init(
            books: IdentifiedArrayOf<Book> = IdentifiedArrayOf<Book>(),
            text: String = "",
            selectedDate: Date = Date(),
            suggestedTokens: IdentifiedArrayOf<SearchToken> = IdentifiedArrayOf<SearchToken>(),
            tokens: IdentifiedArrayOf<SearchToken> = IdentifiedArrayOf<SearchToken>(),
            destination: Destination.State? = nil
        ) {
            self.books = books
            self.text = text
            self.selectedDate = selectedDate
            self.suggestedTokens = suggestedTokens
            self.tokens = tokens
            self.destination = destination
        }
    }

    public enum Action {
        /// 閉じるボタンタップ時の `Action`.
        case closeButtonTapped
        /// 画面遷移用の `Action`.
        case destination(PresentationAction<Destination.Action>)
        /// 画面下部のツールバーボタンがタップされた時の `Action`.
        case filterButtonTapped
        /// テキスト編集が完了した時の `Action`.
        case onSubmit
        /// 検索処理完了時の `Action`.
        case response(Result<[Book], Error>)
        /// テキストフィール横のキャンセルボタンタップ時の `Action`.
        case searchCanceled
        /// サジェストされたトークンがタップされた時の `Action`.
        case suggestedTokenTapped(Int)
        /// テキストフィールドの文字が変更された時の `Action`.
        case textChanged(String)
        /// 選択されたトークンが変更された時の `Action`
        case tokensChanged(IdentifiedArrayOf<SearchToken>)
    }

    @Dependency(\.dismiss) var dismiss
    @Dependency(\.firestoreClient) var firestoreClient

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .closeButtonTapped:

                return .run { _ in
                    await self.dismiss()
                }
            case let .destination(.presented(.form(.delegate(.confirmed(setting))))):
                // 日付の内時間を削った状態にする
                let (date, _) = setting.date.startAndEnd

                if state.selectedDate != date {
                    state.selectedDate = date
                }

                return .run { [state] send in
                    let selectedToken = state.tokens.first
                    await send(
                        .response(
                            Result {
                                try await self.search(
                                    with: date,
                                    title: state.text,
                                    author: selectedToken?.type == .author ? selectedToken?.title : nil
                                )
                            }
                        )
                    )
                }
            case .destination:

                return .none
            case .filterButtonTapped:
                state.destination = .form(
                    SearchForm.State(
                        selectedDate: state.selectedDate
                    )
                )

                return .none
            case .onSubmit:
                state.suggestedTokens = []

                return .run { [state] send in
                    let selectedToken = state.tokens.first
                    await send(
                        .response(
                            Result {
                                try await self.search(
                                    with: state.selectedDate,
                                    title: state.text,
                                    author: selectedToken?.type == .author ? selectedToken?.title : nil
                                )
                            }
                        )
                    )
                }
            case let .response(.success(books)):
                state.books = IdentifiedArrayOf(uniqueElements: books)

                return .none
            case let .response(.failure(error)):
                state.books = []
                print(error)

                return .none
            case .searchCanceled:
                state.books = []

                return .none
            case let .suggestedTokenTapped(index):
                // トークン選択後のテキストをクリアするために必要.
                state.text = ""

                let token = state.suggestedTokens[index]
                state.tokens = IdentifiedArrayOf(uniqueElements: [token])
                state.suggestedTokens = []

                // ここで検索はされないが、テキストを空文字にしたことで `textChanged` が発火するため検索が行われる.
                return .none
            case let .textChanged(text):
                state.text = text

                if !text.trimmingCharacters(in: .whitespaces).isEmpty {
                    state.suggestedTokens = IdentifiedArrayOf(
                        uniqueElements: SearchToken.presets(with: text)
                    )
                } else {
                    state.suggestedTokens = []
                }

                return .none
            case let .tokensChanged(tokens):
                state.tokens = tokens

                return .none
            }
        }
        .ifLet(\.$destination, action: \.destination) {
            Destination()
        }
    }

    public init() {}
}

private extension SearchFeature {
    func search(
        with date: Date,
        title: String? = nil,
        author: String? = nil
    ) async throws -> [Book] {
        // テキストフィールドに空文字が入る場合は無視する.
        try await firestoreClient.searchBooks(
            FirestoreClient.SearchBooksRequest(
                date: date,
                title: title?.isEmpty == true ? nil : title,
                author: author
            )
        )
    }
}

// MARK: - View

public struct SearchView: View {
    let store: StoreOf<SearchFeature>

    public var body: some View {
        WithViewStore(store, observe: { $0 }) { viewStore in
            VStack(spacing: 0) {
                SearchCancellableView { isSearching in
                    ScrollView {
                        LazyVStack {
                            ForEach(
                                Array(viewStore.state.books.enumerated()),
                                id: \.offset
                            ) { enumerated in
                                LargeThumbnailView(
                                    configuration: LargeThumbnailView.Configuration(
                                        title: enumerated.element.title,
                                        imageURL: enumerated.element.thumbnailURL,
                                        createdAt: enumerated.element.createdAt.string(for: .medium, timeStyle: .short)
                                    )
                                )
                            }
                        }
                    }
                    .onChange(of: isSearching) { newValue in
                        if !newValue {
                            viewStore.send(.searchCanceled)
                        }
                    }
                }
            }
            .navigationTitle("検索")
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
                ToolbarItemGroup(placement: .bottomBar) {
                    // ボタンを右端に配置するための `Spacer`.
                    Spacer()
                    Button(action: {
                        viewStore.send(.filterButtonTapped)
                    }, label: {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                    })
                }
            }
            .searchable(
                text: viewStore.binding(get: \.text, send: { .textChanged($0) }),
                tokens: viewStore.binding(get: \.tokens, send: { .tokensChanged($0) }),
                prompt: "検索キーワード"
            ) { token in
                SearchTokenView(
                    title: token.title,
                    tokenType: token.type
                )
            }
            .searchSuggestions {
                // サジェストが設定されている場合にのみ要素を表示させる.
                if !viewStore.suggestedTokens.isEmpty {
                    Section("候補") {
                        ForEach(
                            Array(viewStore.suggestedTokens.enumerated()),
                            id: \.offset
                        ) { enumerated in
                            SearchTokenView(
                                title: enumerated.element.title,
                                tokenType: enumerated.element.type
                            ) {
                                // トークンタップ後に検索が行われるがキーボードが閉じられないのでワークアラウンドとして UIKit を利用する.
                                UIApplication.shared.sendAction(
                                    #selector(UIResponder.resignFirstResponder),
                                    to: nil,
                                    from: nil,
                                    for: nil
                                )
                                viewStore.send(.suggestedTokenTapped(enumerated.offset))
                            }
                        }
                    }
                }
            }
            .onSubmit(of: .search) {
                viewStore.send(.onSubmit)
            }
            .sheet(
                store: store.scope(
                    state: \.$destination.form,
                    action: \.destination.form
                )
            ) { store in
                NavigationStack {
                    SearchFormView(store: store)
                }
            }
        }
    }

    public init(store: StoreOf<SearchFeature>) {
        self.store = store
    }
}

// MARK: - Preview

#if DEBUG
#Preview {
    NavigationView {
        SearchView(
            store: Store(initialState: SearchFeature.State()) {
                SearchFeature()
            }
        )
    }
}
#endif

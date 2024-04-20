//
//  SearchView.swift
//
//
//  Created by Shunya Yamada on 2024/02/24.
//

import ComposableArchitecture
import SharedExtensions
import SharedModels
import SwiftUI

// MARK: - Reducer

@Reducer
public struct SearchFeature {
    public struct State: Equatable {
        public var books = IdentifiedArrayOf<Book>()
        public var text = ""
        public var selectedDate = Date()
        public var suggestedTokens = IdentifiedArrayOf<SearchToken>()
        public var tokens = IdentifiedArrayOf<SearchToken>()

        public init(
            books: IdentifiedArrayOf<Book> = IdentifiedArrayOf<Book>(),
            text: String = "",
            selectedDate: Date = Date(),
            suggestedTokens: IdentifiedArrayOf<SearchToken> = IdentifiedArrayOf<SearchToken>(),
            tokens: IdentifiedArrayOf<SearchToken> = IdentifiedArrayOf<SearchToken>()
        ) {
            self.books = books
            self.text = text
            self.selectedDate = selectedDate
            self.suggestedTokens = suggestedTokens
            self.tokens = tokens
        }
    }

    public enum Action {
        /// 閉じるボタンタップ時の `Action`.
        case closeButtonTapped
        /// テキスト編集が完了した時の `Action`.
        case onSubmit
        /// 検索処理完了時の `Action`.
        case response(Result<[Book], Error>)
        /// `DatePicker` で選択された日付が変更された時の `Action`.
        case selectedDateChanged(Date)
        /// サジェストされたトークンがタップされた時の `Action`.
        case suggestedTokenTapped(Int)
        /// テキストフィールドの文字が変更された時の `Action`.
        case textChanged(String)
        /// 選択されたトークンが変更された時の `Action`
        case tokensChanged(IdentifiedArrayOf<SearchToken>)
    }

    @Dependency(\.dismiss) var dismiss

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .closeButtonTapped:

                return .run { _ in
                    await self.dismiss()
                }
            case .onSubmit:

                return .none
            case let .response(.success(books)):
                state.books = IdentifiedArrayOf(uniqueElements: books)

                return .none
            case let .response(.failure(error)):
                state.books = []
                print(error)

                return .none
            case let .suggestedTokenTapped(index):
                // トークン選択後のテキストをクリアするために必要.
                state.text = ""
                state.tokens = IdentifiedArrayOf(uniqueElements: [state.suggestedTokens[index]])
                state.suggestedTokens = []

                return .none
            case let .selectedDateChanged(date):
                state.selectedDate = date
                state.text = ""
                state.tokens = IdentifiedArrayOf(
                    uniqueElements: [
                        SearchToken(
                            title: "日付: \(date.string(for: .short))",
                            type: .date
                        )
                    ]
                )
                state.suggestedTokens = []

                return .none
            case let .textChanged(text):
                state.text = text

                if !text.trimmingCharacters(in: .whitespaces).isEmpty {
                    state.suggestedTokens = IdentifiedArrayOf(
                        uniqueElements: SearchToken.presets(with: text)
                    )
                } else if state.tokens.isEmpty {
                    state.suggestedTokens = IdentifiedArrayOf(
                        uniqueElements: [
                            SearchToken(
                                title: "",
                                type: .date
                            )
                        ]
                    )
                }

                return .none
            case let .tokensChanged(tokens):
                state.tokens = tokens

                return .none
            }
        }
    }

    public init() {}
}

// MARK: - View

public struct SearchView: View {
    let store: StoreOf<SearchFeature>

    public var body: some View {
        WithViewStore(store, observe: { $0 }) { viewStore in
            ScrollView {
                LazyVStack {
                    ForEach(
                        Array(viewStore.state.books.enumerated()),
                        id: \.offset
                    ) { enumerated in
                        Text(enumerated.element.title)
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
                            // `DatePicker` 表示用の View と分ける.
                            if case .date = enumerated.element.type {
                                SearchTokenDateView(
                                    selection: viewStore.binding(get: \.selectedDate, send: { .selectedDateChanged($0) })
                                )
                            } else {
                                SearchTokenView(
                                    title: enumerated.element.title,
                                    tokenType: enumerated.element.type
                                ) {
                                    viewStore.send(.suggestedTokenTapped(enumerated.offset))
                                }
                            }
                        }
                    }
                }
            }
            .onSubmit {
                viewStore.send(.onSubmit)
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

//
//  BookView.swift
//  
//
//  Created by Shunya Yamada on 2024/05/01.
//

import ClipboardClient
import ComposableArchitecture
import SharedExtensions
import SharedModels
import SwiftUI

// MARK: - Reducer

@Reducer
public struct BookFeature {
    public struct State: Equatable {
        public let book: Book
        @PresentationState public var confirmationDialog: ConfirmationDialogState<Action.ConfirmationDialog>?

        public init(
            book: Book,
            confirmationDialog: ConfirmationDialogState<Action.ConfirmationDialog>? = nil
        ) {
            self.book = book
            self.confirmationDialog = confirmationDialog
        }
    }

    public enum Action {
        /// 作者名のボタンタップ時の `Action`.
        case authorButtonTapped
        /// 閉じるボタンタップ時の `Action`.
        case closeButtonTapped
        /// Action Sheet 表示用の `Action`.
        case confirmationDialog(PresentationAction<ConfirmationDialog>)
        /// URL のボタンタップ時の `Action`.
        case urlButtonTapped

        public enum ConfirmationDialog {
            /// 作者名をコピーする.
            case copyAuthor
            /// ID をコピーする.
            case copyID
            /// URL をコピーする.
            case copyURL
            /// 作者名で検索する.
            case searchWithAuthor
        }
    }

    @Dependency(\.clipboardClient) var clipboardClient
    @Dependency(\.dismiss) var dismiss

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .authorButtonTapped:
                state.confirmationDialog = makeAuthorConfirmationDialogState(author: state.book.author)

                return .none
            case .closeButtonTapped:

                return .run { _ in
                    await self.dismiss()
                }
            case .confirmationDialog(.presented(.copyAuthor)):
                clipboardClient.setString(state.book.author ?? "")

                return .none
            case .confirmationDialog(.presented(.copyURL)):
                clipboardClient.setString(state.book.url)

                return .none
            case .confirmationDialog:

                return .none
            case .urlButtonTapped:
                state.confirmationDialog = makeURLConfirmationDialogState(url: state.book.url)

                return .none
            }
        }
        .ifLet(\.$confirmationDialog, action: \.confirmationDialog)
    }

    public init() {}
}

private extension BookFeature {
    /// 作者のボタンタップ時に表示する Action Sheet の内容を作る.
    /// - Parameter author: 作者名.
    /// - Returns: Action Sheet の内容
    func makeAuthorConfirmationDialogState(author: String?) -> ConfirmationDialogState<Action.ConfirmationDialog> {
        ConfirmationDialogState {
            TextState("作者")
        } actions: {
            ButtonState(role: .cancel) {
                TextState("キャンセル")
            }
            ButtonState(action: .copyAuthor) {
                TextState("作者名をコピーする")
            }
            ButtonState(action: .searchWithAuthor) {
                TextState("作者名で検索する")
            }
        } message: {
            TextState(author ?? "")
        }
    }

    /// URL ボタンタップ時に表示する Action Sheet の内容を作る.
    /// - Parameter url: 作品のURL.
    /// - Returns: Action Sheet の内容
    func makeURLConfirmationDialogState(url: String) -> ConfirmationDialogState<Action.ConfirmationDialog> {
        ConfirmationDialogState {
            TextState("URL")
        } actions: {
            ButtonState(role: .cancel) {
                TextState("キャンセル")
            }
            ButtonState(action: .copyURL) {
                TextState("URL をコピーする")
            }
        } message: {
            TextState(url)
        }
    }
}

// MARK: - View

public struct BookView: View {
    let store: StoreOf<BookFeature>

    public var body: some View {
        WithViewStore(store, observe: { $0 }) { viewStore in
            List {
                Section {
                    Text(viewStore.book.title)
                        .bold()
                } header: {
                    Text("作品タイトル")
                        .foregroundStyle(.secondary)
                }

                Section {
                    HStack {
                        Text("追加日時")
                            .bold()
                        Spacer()
                        Text(viewStore.book.createdAt.string(for: .short, timeStyle: .short))
                    }

                    if let id = viewStore.book.id {
                        Button(action: {

                        }, label: {
                            HStack {
                                Text("ID")
                                    .bold()
                                Spacer()
                                Text(id)
                                    .multilineTextAlignment(.trailing)
                                    .foregroundStyle(Color(.link))
                            }
                        })
                    }

                    if let author = viewStore.book.author {
                        Button(action: {
                            viewStore.send(.authorButtonTapped)
                        }, label: {
                            HStack {
                                Text("作者")
                                    .bold()
                                Spacer()
                                Text(author)
                                    .multilineTextAlignment(.trailing)
                                    .foregroundStyle(Color(.link))
                            }
                        })
                    }

                    Button(action: {
                        viewStore.send(.urlButtonTapped)
                    }, label: {
                        HStack {
                            Text("URL")
                                .bold()
                            Spacer()
                            Text(viewStore.book.url)
                                .multilineTextAlignment(.trailing)
                                .foregroundStyle(Color(.link))
                        }
                    })
                } header: {
                    Text("作品情報")
                        .foregroundStyle(.secondary)
                }

                let joinedCategories = viewStore.book.categories.reduce(into: "") { $0 += $1 + " " }
                if !joinedCategories.isEmpty {
                    Section {
                        Text(joinedCategories)
                    } header: {
                        Text("作品カテゴリー")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .font(.caption)
            .foregroundStyle(Color(.label))
        }
        .navigationTitle("作品詳細")
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
        .confirmationDialog(
            store: store.scope(
                state: \.$confirmationDialog,
                action: \.confirmationDialog
            )
        )
    }

    public init(store: StoreOf<BookFeature>) {
        self.store = store
    }
}

// MARK: - Preview

#Preview {
    BookView(
        store: Store(
            initialState: BookFeature.State(
                book: Book(
                    id: UUID().uuidString + UUID().uuidString,
                    title: "私の哀愁はこの夏あなたから二、三日保つだろうかそれでいて自分の心をＫに打ち明けようと思い立ってから、急に瞑想から呼息を吹き返した人のようにきまりが悪かった。",
                    url: "https://example.com",
                    createdAt: Date(),
                    imageURLs: [],
                    categories: [],
                    author: "夏目漱石",
                    thumbnailURL: ""
                )
            )
        ) {
            BookFeature()
        }
    )
}

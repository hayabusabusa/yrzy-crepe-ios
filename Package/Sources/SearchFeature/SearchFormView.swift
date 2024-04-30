//
//  SearchFormView.swift
//
//
//  Created by Shunya Yamada on 2024/04/29.
//

import SwiftUI
import ComposableArchitecture

// MARK: - Reducer

@Reducer
public struct SearchForm {
    public struct State: Equatable {
        @BindingState public var isDescending = true
        @BindingState public var selectedDate = Date()

        public init(
            isDescending: Bool = true,
            selectedDate: Date = Date()
        ) {
            self.isDescending = isDescending
            self.selectedDate = selectedDate
        }
    }

    public enum Action: BindableAction {
        case binding(BindingAction<State>)
        case cancelButtonTapped
        case confirmButtonTapped
        case delegate(Delegate)

        public enum Delegate {
            case confirmed(SearchSetting)
        }
    }

    @Dependency(\.dismiss) var dismiss

    public var body: some ReducerOf<Self> {
        BindingReducer()
        Reduce { state, action in
            switch action {
            case .binding:

                return .none
            case .cancelButtonTapped:

                return .run { _ in
                    await self.dismiss()
                }
            case .confirmButtonTapped:

                return .run { [state] send in
                    await send(
                        .delegate(
                            .confirmed(
                                SearchSetting(
                                    date: state.selectedDate,
                                    isDescending: state.isDescending
                                )
                            )
                        )
                    )
                    await self.dismiss()
                }
            case .delegate:

                return .none
            }
        }
    }

    public init() {}
}

// MARK: - View

/// 検索時の設定を決める `View`.
public struct SearchFormView: View {
    let store: StoreOf<SearchForm>

    public var body: some View {
        WithViewStore(store, observe: { $0 }) { viewStore in
            Form {
                Section("検索設定") {
                    HStack {
                        Toggle(
                            "日付降順",
                            isOn: viewStore.$isDescending
                        )
                    }

                    HStack {
                        DatePicker(
                            "日付",
                            selection: viewStore.$selectedDate,
                            displayedComponents: .date
                        )
                    }
                }
            }
            .navigationTitle("検索設定")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: {
                        viewStore.send(.confirmButtonTapped)
                    }, label: {
                        Text("適応")
                            .bold()
                    })
                }
                ToolbarItem(placement: .topBarLeading) {
                    Button(action: {
                        viewStore.send(.cancelButtonTapped)
                    }, label: {
                        Text("キャンセル")
                    })
                }
            }
        }
    }

    public init(store: StoreOf<SearchForm>) {
        self.store = store
    }
}

#Preview {
    SearchFormView(
        store: Store(initialState: SearchForm.State()) {
            SearchForm()
        }
    )
}

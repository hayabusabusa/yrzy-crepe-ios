//
//  ViewerView.swift
//
//
//  Created by Shunya Yamada on 2024/02/10.
//

import ComposableArchitecture
import NukeUI
import SharedModels
import SwiftUI
import SwiftUIPager

// MARK: - Reducer

@Reducer
public struct ViewerFeature {
    public struct State: Equatable {
        var book: Book
        var pageIndex: Int
        var sliderValue: Double

        public init(book: Book) {
            self.book = book
            self.pageIndex = 0
            self.sliderValue = Double(book.imageURLs.count - 1)
        }
    }

    public enum Action {
        /// 閉じるボタンタップ時の `Action`.
        case closeButtonTapped
        /// Pager のページが切り替わった時の `Action`.
        case pageChanged(Int)
        /// スライダーの値が変化した時の `Action`.
        case sliderValueChanged(Double)
    }

    @Dependency(\.dismiss) var dismiss

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
            case let .sliderValueChanged(value):
                state.pageIndex = (state.book.imageURLs.count - 1) - Int(value)
                state.sliderValue = value

                return .none
            }
        }
    }

    public init() {}
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
                    PageView(configuration: configuration)
                }
                .onPageWillChange { pageIndex in
                    viewStore.send(.pageChanged(pageIndex))
                }
                .horizontal(.endToStart)
                .itemAspectRatio(1)

                Slider(
                    value: viewStore.binding(get: \.sliderValue, send: { .sliderValueChanged($0) }),
                    in: 0...Double(viewStore.book.imageURLs.count - 1),
                    step: 1
                )
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
                            .foregroundStyle(Color(uiColor: .systemGray.withAlphaComponent(0.3)))
                    })
                }
            }
        }
    }

    public init(store: StoreOf<ViewerFeature>) {
        self.store = store
    }
}

private extension ViewerView {
    func makeConfigurations(fromImageURLs imageURLs: [String]) -> [PageView.Configuration] {
        imageURLs
            .compactMap { URL(string: $0) }
            .map {
                PageView.Configuration(
                    id: $0.absoluteString,
                    imageURL: $0
                )
            }
    }
}

extension ViewerView {
    struct PageView: View {
        var configuration: Configuration

        var body: some View {
            LazyImage(url: configuration.imageURL) { state in
                if let image = state.image {
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } else {
                    Color(.secondarySystemBackground)
                }
            }
        }
    }
}

extension ViewerView.PageView {
    struct Configuration: Identifiable, Hashable {
        let id: String
        let imageURL: URL
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

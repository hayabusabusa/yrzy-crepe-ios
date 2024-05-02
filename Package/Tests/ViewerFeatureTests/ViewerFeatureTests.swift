//
//  ViewerFeatureTests.swift
//
//
//  Created by Shunya Yamada on 2024/05/02.
//

import ComposableArchitecture
import SharedModels
import XCTest

@testable import ViewerFeature

@MainActor
final class ViewerFeatureTests: XCTestCase {
    func testFetchFavoriteBook() async {
        let date = Date()

        let store = TestStore(
            initialState: ViewerFeature.State(
                source: .favoriteBook(
                    FavoriteBook(
                        id: "0",
                        title: "0",
                        createdAt: date,
                        publishedAt: date,
                        thumbnailURL: nil
                    )
                )
            )
        ) {
            ViewerFeature()
        } withDependencies: {
            $0.authClient.uid = { "uid" }
            $0.firestoreClient.fetchBook = { _ in
                Book(
                    id: "0",
                    title: "0",
                    url: "https://example.com",
                    createdAt: date,
                    imageURLs: [
                        "https://example.com"
                    ],
                    categories: [],
                    author: nil,
                    thumbnailURL: nil
                )
            }
            $0.firestoreClient.favoriteBookExists = { _ in
                false
            }
        }

        await store.send(.task) {
            $0.isLoading = true
        }
        await store.receive(\.response) {
            $0.book = Book(
                id: "0",
                title: "0",
                url: "https://example.com",
                createdAt: date,
                imageURLs: [
                    "https://example.com"
                ],
                categories: [],
                author: nil,
                thumbnailURL: nil
            )
            $0.isFavorite = false
            $0.pageIndex = 0
            $0.sliderValue = 0
            $0.isLoading = false
        }
    }

    func testToggleIsFavorite() async {
        let date = Date()

        let store = TestStore(
            initialState: ViewerFeature.State(
                source: .book(
                    Book(
                        id: "0",
                        title: "0",
                        url: "https://example.com",
                        createdAt: date,
                        imageURLs: [
                            "https://example.com"
                        ],
                        categories: [],
                        author: nil,
                        thumbnailURL: nil
                    )
                ),
                book: Book(
                    id: "0",
                    title: "0",
                    url: "https://example.com",
                    createdAt: date,
                    imageURLs: [
                        "https://example.com"
                    ],
                    categories: [],
                    author: nil,
                    thumbnailURL: nil
                ),
                isFavorite: false
            )
        ) {
            ViewerFeature()
        } withDependencies: {
            $0.date.now = {
                date
            }()
            $0.authClient.uid = { "uid" }
            $0.firestoreClient.addFavoriteBook = { _ in }
            $0.firestoreClient.removeFavoriteBook = { _ in }
        }

        await store.send(.favoriteButtonTapped) {
            $0.isFavoriteLoading = true
        }
        await store.receive(\.toggleIsFavoriteResponse) {
            $0.isFavorite = true
            $0.isFavoriteLoading = false
        }

        await store.send(.favoriteButtonTapped) {
            $0.isFavoriteLoading = true
        }
        await store.receive(\.toggleIsFavoriteResponse) {
            $0.isFavorite = false
            $0.isFavoriteLoading = false
        }
    }
}

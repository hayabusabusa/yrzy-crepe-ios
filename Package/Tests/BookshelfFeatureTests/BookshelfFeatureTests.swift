//
//  BookshelfFeatureTests.swift
//
//
//  Created by Shunya Yamada on 2024/05/01.
//

import ComposableArchitecture
import XCTest
import SharedModels

@testable import BookshelfFeature

@MainActor
final class BookshelfFeatureTests: XCTestCase {
    func testFetchBooks() async {
        let date = Date()

        let store = TestStore(initialState: BookshelfFeature.State(collection: .latest)) {
            BookshelfFeature()
        } withDependencies: {
            $0.date.now = {
                date
            }()
            $0.firestoreClient.fetchLatestBooks = { _ in
                [
                    Book(
                        id: "0",
                        title: "0",
                        url: "https://example.com",
                        createdAt: date,
                        imageURLs: [],
                        categories: [],
                        author: nil,
                        thumbnailURL: nil
                    )
                ]
            }
        }

        await store.send(.task)
        await store.receive(\.response) {
            $0.books = [
                Book(
                    id: "0",
                    title: "0",
                    url: "https://example.com",
                    createdAt: date,
                    imageURLs: [],
                    categories: [],
                    author: nil,
                    thumbnailURL: nil
                )
            ]
        }
    }

    func testFetchNextBooks() async {
        let date = Date()

        let store = TestStore(
            initialState: BookshelfFeature.State(
                collection: .latest,
                books: [
                    Book(
                        id: "0",
                        title: "0",
                        url: "https://example.com",
                        createdAt: date,
                        imageURLs: [],
                        categories: [],
                        author: nil,
                        thumbnailURL: nil
                    ),
                    Book(
                        id: "1",
                        title: "1",
                        url: "https://example.com",
                        createdAt: date,
                        imageURLs: [],
                        categories: [],
                        author: nil,
                        thumbnailURL: nil
                    )
                ]
            )
        ) {
            BookshelfFeature()
        } withDependencies: {
            $0.date.now = {
                date
            }()
            $0.firestoreClient.fetchLatestBooks = { _ in
                [
                    Book(
                        id: "2",
                        title: "2",
                        url: "https://example.com",
                        createdAt: date,
                        imageURLs: [],
                        categories: [],
                        author: nil,
                        thumbnailURL: nil
                    )
                ]
            }
        }

        await store.send(.onAppearScrollViewContent(0)) {
            $0.isPaginationLoading = true
        }
        await store.receive(\.paginationResponse) {
            $0.isPaginationLoading = false
            $0.books = [
                Book(
                    id: "0",
                    title: "0",
                    url: "https://example.com",
                    createdAt: date,
                    imageURLs: [],
                    categories: [],
                    author: nil,
                    thumbnailURL: nil
                ),
                Book(
                    id: "1",
                    title: "1",
                    url: "https://example.com",
                    createdAt: date,
                    imageURLs: [],
                    categories: [],
                    author: nil,
                    thumbnailURL: nil
                ),
                Book(
                    id: "2",
                    title: "2",
                    url: "https://example.com",
                    createdAt: date,
                    imageURLs: [],
                    categories: [],
                    author: nil,
                    thumbnailURL: nil
                )
            ]
        }
    }

    func testBookTapped() async {
        let date = Date()

        let store = TestStore(
            initialState: BookshelfFeature.State(
                collection: .latest,
                books: [
                    Book(
                        id: "0",
                        title: "0",
                        url: "https://example.com",
                        createdAt: date,
                        imageURLs: [],
                        categories: [],
                        author: nil,
                        thumbnailURL: nil
                    )
                ]
            )
        ) {
            BookshelfFeature()
        } withDependencies: {
            $0.date.now = {
                date
            }()
        }

        await store.send(.bookTapped(0)) {
            $0.viewer = .init(
                source: .book(
                    Book(
                        id: "0",
                        title: "0",
                        url: "https://example.com",
                        createdAt: date,
                        imageURLs: [],
                        categories: [],
                        author: nil,
                        thumbnailURL: nil
                    )
                )
            )
        }
    }
}

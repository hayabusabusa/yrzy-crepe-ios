//
//  ClipboardClientTests.swift
//
//
//  Created by Shunya Yamada on 2024/05/01.
//

import XCTest
@testable import ClipboardClient

final class ClipboardClientTests: XCTestCase {
    var clipboardClient: ClipboardClient {
        .liveValue
    }

    func testString() {
        XCTContext.runActivity(named: "文字列をクリップボードにコピーすることができること") { _ in
            let expected = "string"
            clipboardClient.setString(expected)
            XCTAssertEqual(clipboardClient.getString(), expected)
        }
    }
}

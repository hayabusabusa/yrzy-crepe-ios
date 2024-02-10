//
//  DateTests.swift
//
//
//  Created by Shunya Yamada on 2024/02/10.
//

import XCTest
@testable import SharedExtensions

final class DateTests: XCTestCase {
    func testStartAndEnds() {
        let calendar = Calendar.current
        let startAndEnd = stubDate.startAndEnd

        XCTContext.runActivity(named: "1日の始まりが正しく返せること") { _ in
            let expected = calendar.date(
                from: DateComponents(
                    year: 1996,
                    month: 1,
                    day: 12,
                    hour: 0,
                    minute: 0,
                    second: 0
                )
            )!
            XCTAssertEqual(startAndEnd.start, expected)
        }

        XCTContext.runActivity(named: "1日の終わりが正しく返せること") { _ in
            let expected = calendar.date(
                from: DateComponents(
                    year: 1996,
                    month: 1,
                    day: 12,
                    hour: 23,
                    minute: 59,
                    second: 59
                )
            )!
            XCTAssertEqual(startAndEnd.end, expected)
        }
    }

    func testLastYear() {
        XCTContext.runActivity(named: "任意の日付から1年前の日付を正しく返せること") { _ in
            let expected = Calendar.current.date(
                from: DateComponents(
                    year: 1995,
                    month: 1,
                    day: 12,
                    hour: 12,
                    minute: 30
                )
            )
            XCTAssertEqual(stubDate.lastYear, expected)
        }
    }
}

private extension DateTests {
    var stubDate: Date {
        var dateComponents = DateComponents()
        dateComponents.year = 1996
        dateComponents.month = 1
        dateComponents.day = 12
        dateComponents.hour = 12
        dateComponents.minute = 30
        return Calendar.current.date(from: dateComponents)!
    }
}

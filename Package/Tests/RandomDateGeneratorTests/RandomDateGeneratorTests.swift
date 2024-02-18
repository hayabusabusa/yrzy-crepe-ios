//
//  RandomDateGeneratorTests.swift
//  
//
//  Created by Shunya Yamada on 2024/02/18.
//

import Dependencies
import XCTest
@testable import RandomDateGenerator

final class RandomDateGeneratorTests: XCTestCase {
    var randomDateGenerator: RandomDateGenerator {
        .liveValue
    }

    func testGenerate() {
        XCTContext.runActivity(named: "指定した範囲の中からランダムな日付を生成できること") { _ in
            let calendar = Calendar.current
            let since = calendar.date(
                from: DateComponents(
                    year: 2024,
                    month: 2,
                    day: 18,
                    hour: 0,
                    minute: 0,
                    second: 0
                )
            )!
            let until = calendar.date(
                from: DateComponents(
                    year: 2024,
                    month: 2,
                    day: 18,
                    hour: 23,
                    minute: 59,
                    second: 59
                )
            )!
            let period = RandomDateGenerator.Period(
                since: since,
                until: until
            )
            XCTAssertTrue((since...until).contains(randomDateGenerator.generate(period)))
        }
    }

    func testSinceServiceLaunched() {
        XCTContext.runActivity(named: "その日からサービス開始時までの範囲でランダムな日付を生成できること") { _ in
            let since = Calendar.current.date(
                from: DateComponents(
                    year: 2021,
                    month: 12,
                    day: 5
                )
            )!
            let until = Date()
            XCTAssertTrue((since...until).contains(randomDateGenerator.sinceServiceLaunched()))
        }
    }
}

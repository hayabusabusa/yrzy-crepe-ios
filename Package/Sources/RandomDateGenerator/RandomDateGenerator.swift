//
//  RandomDateGenerator.swift
//
//
//  Created by Shunya Yamada on 2024/02/18.
//

import Dependencies
import Foundation

/// ランダムな日付を生成するジェネレーター.
public struct RandomDateGenerator {
    /// ランダムな日付を生成する.
    public var generate: @Sendable (Period) -> Date
    /// 任意の日付から最も古いデータの保存日までの間でランダムな日付を生成する.
    public var sinceServiceLaunched: @Sendable () -> Date

    public init(
        generate: @Sendable @escaping (Period) -> Date,
        sinceServiceLaunched: @Sendable @escaping () -> Date
    ) {
        self.generate = generate
        self.sinceServiceLaunched = sinceServiceLaunched
    }
}

public extension RandomDateGenerator {
    /// ランダムに日付を生成する際に利用する期間.
    struct Period: Equatable {
        public let since: Date
        public let until: Date

        public init(
            since: Date,
            until: Date
        ) {
            self.since = since
            self.until = until
        }
    }
}

// MARK: - Dependencies

extension RandomDateGenerator: TestDependencyKey {
    public static var previewValue: RandomDateGenerator {
        .init { _ in
            Date()
        } sinceServiceLaunched: {
            Date()
        }
    }

    public static var testValue: RandomDateGenerator {
        .init { _ in
            unimplemented("\(Self.self)\(#function)")
        } sinceServiceLaunched: {
            unimplemented("\(Self.self)\(#function)")
        }

    }
}

extension RandomDateGenerator: DependencyKey {
    public static var liveValue: RandomDateGenerator {
        @Sendable func _generate(with period: Period) -> Date {
            let interval = period.until.timeIntervalSince(period.since)
            let randomInterval = TimeInterval.random(in: 0..<interval)
            return period.since.addingTimeInterval(randomInterval)
        }

        return .init { period in
            return _generate(with: period)
        } sinceServiceLaunched: {
            let launchDateComponents = DateComponents(
                year: 2021,
                month: 12,
                day: 5
            )
            let launchDate = Calendar.current.date(from: launchDateComponents) ?? Date()
            return _generate(
                with: Period(
                    since: launchDate,
                    until: Date()
                )
            )
        }
    }
}

extension DependencyValues {
    public var randomDateGenerator: RandomDateGenerator {
        get { self[RandomDateGenerator.self] }
        set { self[RandomDateGenerator.self] = newValue }
    }
}

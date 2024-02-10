//
//  Date+.swift
//
//
//  Created by Shunya Yamada on 2024/02/10.
//

import Foundation

public extension Date {
    /// その日の始まり( 0 時 0 分 )と終わり( 23 時 59 分 )を返す.
    var startAndEnd: (start: Date, end: Date) {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: self)
        let end = calendar.date(byAdding: DateComponents(day: 1, second: -1), to: start) ?? self
        return (start: start, end: end)
    }

    /// 現在から 1 年前の日付を返す.
    var lastYear: Date {
        let calendar = Calendar.current
        var component = DateComponents()
        component.year = -1
        return calendar.date(byAdding: component, to: self) ?? self
    }
}

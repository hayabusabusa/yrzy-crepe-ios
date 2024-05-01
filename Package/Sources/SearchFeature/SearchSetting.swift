//
//  SearchSetting.swift
//  
//
//  Created by Shunya Yamada on 2024/04/30.
//

import Foundation

/// 検索の設定.
public struct SearchSetting {
    public let date: Date
    public let isDescending: Bool

    public init(
        date: Date,
        isDescending: Bool
    ) {
        self.date = date
        self.isDescending = isDescending
    }
}

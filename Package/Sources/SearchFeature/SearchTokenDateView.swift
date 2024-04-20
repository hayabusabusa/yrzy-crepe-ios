//
//  SearchTokenDateView.swift
//
//
//  Created by Shunya Yamada on 2024/04/20.
//

import SwiftUI

struct SearchTokenDateView: View {
    @Binding var selection: Date

    var body: some View {
        DatePicker(
            "日付から検索",
            selection: $selection,
            displayedComponents: [.date]
        )
        .foregroundStyle(Color.blue)
    }
}

//
//  SearchTokenView.swift
//
//
//  Created by Shunya Yamada on 2024/04/20.
//

import SwiftUI

struct SearchTokenView: View {
    var title: String
    var tokenType: SearchToken.TokenType
    var action: (() -> Void)?

    var body: some View {
        Button(action: {
            action?()
        }, label: {
            HStack {
                Image(systemName: tokenType.imageName)
                    .frame(width: 24, height: 24)
                Text(title)
            }
        })
    }
}

private extension SearchToken.TokenType {
    var imageName: String {
        switch self {
        case .author:
            "person"
        case .date:
            "calendar"
        }
    }
}

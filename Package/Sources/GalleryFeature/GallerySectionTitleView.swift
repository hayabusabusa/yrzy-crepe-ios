//
//  GallerySectionTitleView.swift
//
//
//  Created by Shunya Yamada on 2024/01/12.
//

import SwiftUI

struct GallerySectionTitleView: View {
    var title: String
    var buttonTitle: String
    var action: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            Text(title)
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            Button(action: {
                action()
            }, label: {
                Text(buttonTitle)
                    .font(.caption)
            })
        }
        .padding(EdgeInsets(top: 8, leading: 8, bottom: 8, trailing: 8))
    }
}

#if DEBUG
#Preview {
    GallerySectionTitleView(
        title: "最近追加された作品",
        buttonTitle: "もっとみる",
        action: {  }
    )
}
#endif
